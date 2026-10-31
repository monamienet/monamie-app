// An in-memory Firestore for the central functions' tests (not a test file:
// it only exports `fakeFirestore`). It keeps documents by path and offers
// what the services use: `doc(path)` refs (`get`, `set` with `{merge}`,
// `update`, `delete`, `collection`), `collection(path)` (`add`, `doc`,
// `where`, `get`), `collectionGroup(name).where(...).get()`, `batch()`,
// `getAll`, `recursiveDelete` and `runTransaction` (`tx.get/create/update/set`).
// `FieldValue.delete()`, `arrayUnion` and `arrayRemove` are applied.
const assert = require("node:assert/strict");

const comparable = (value) =>
  value instanceof Date ? value.getTime() : value?.toDate ? value.toDate().getTime() : value;

/** Applies `data` (with FieldValue sentinels) over `previous`. */
function applyFields(previous, data) {
  const next = { ...previous };
  for (const [field, value] of Object.entries(data)) {
    switch (value?.methodName) {
      case "FieldValue.delete":
        delete next[field];
        break;
      case "FieldValue.arrayUnion": {
        const current = Array.isArray(next[field]) ? next[field] : [];
        next[field] = [...current, ...value.elements.filter((e) => !current.includes(e))];
        break;
      }
      case "FieldValue.arrayRemove": {
        const current = Array.isArray(next[field]) ? next[field] : [];
        next[field] = current.filter((e) => !value.elements.includes(e));
        break;
      }
      default:
        next[field] = value;
    }
  }
  return next;
}

function matches(data, [field, op, value]) {
  const actual = data[field];
  switch (op) {
    case "==":
      return actual === value;
    case "<=":
      return actual !== undefined && comparable(actual) <= comparable(value);
    case "in":
      return value.includes(actual);
    case "array-contains":
      return Array.isArray(actual) && actual.includes(value);
    default:
      assert.fail(`the fake does not support ${op}`);
  }
}

/**
 * @param {Object<string, object>} [docs] - Initial documents by path
 * @returns The fake, with `store` (Map of path → data), `statuses` (each
 *   `status` written, by path) and `reads` (documents and queries read)
 */
function fakeFirestore(docs = {}) {
  const store = new Map(Object.entries(docs).map(([path, data]) => [path, { ...data }]));
  const statuses = new Map();
  let reads = 0;
  let autoId = 0;

  const write = (path, data) => {
    store.set(path, data);
    if (data.status !== undefined && statuses.get(path)?.at(-1) !== data.status) {
      statuses.set(path, [...(statuses.get(path) ?? []), data.status]);
    }
  };
  const setDoc = (path, data, options) =>
    write(path, applyFields(options?.merge ? store.get(path) ?? {} : {}, data));
  const updateDoc = (path, data) => {
    if (!store.has(path)) {
      const error = new Error(`No document to update: ${path}`);
      error.code = 5;
      throw error;
    }
    write(path, applyFields(store.get(path), data));
  };

  const snapshot = (path) => {
    const data = store.get(path);
    return {
      id: path.split("/").pop(),
      ref: ref(path),
      exists: data !== undefined,
      data: () => (data === undefined ? undefined : { ...data }),
      get: (field) => data?.[field],
    };
  };

  function ref(path) {
    const parts = path.split("/");
    return {
      path,
      id: parts.at(-1),
      get parent() {
        const parentPath = parts.slice(0, -1).join("/");
        return {
          id: parts.at(-2),
          path: parentPath,
          parent: parts.length > 2 ? ref(parts.slice(0, -2).join("/")) : null,
        };
      },
      async get() {
        reads++;
        return snapshot(path);
      },
      async set(data, options) {
        setDoc(path, data, options);
      },
      async update(data) {
        updateDoc(path, data);
      },
      async delete() {
        store.delete(path);
      },
      collection: (name) => collection(`${path}/${name}`),
    };
  }

  const query = (select, filters) => ({
    where(field, op, value) {
      return query(select, [...filters, [field, op, value]]);
    },
    async get() {
      reads++;
      const docs = [...store.keys()]
        .filter(select)
        .sort()
        .filter((p) => filters.every((filter) => matches(store.get(p), filter)))
        .map(snapshot);
      return { empty: docs.length === 0, size: docs.length, docs };
    },
  });

  function collection(path) {
    const depth = path.split("/").length + 1;
    return {
      ...query((p) => p.startsWith(`${path}/`) && p.split("/").length === depth, []),
      doc: (id) => ref(`${path}/${id ?? `auto${++autoId}`}`),
      async add(data) {
        const created = ref(`${path}/auto${++autoId}`);
        setDoc(created.path, data);
        return created;
      },
    };
  }

  return {
    store,
    statuses,
    get reads() {
      return reads;
    },
    doc: ref,
    collection,
    collectionGroup: (name) =>
      query((p) => {
        const parts = p.split("/");
        return parts.length % 2 === 0 && parts.at(-2) === name;
      }, []),
    async getAll(...refs) {
      return refs.map((r) => snapshot(r.path));
    },
    batch() {
      const writes = [];
      return {
        set(r, data, options) {
          writes.push(() => setDoc(r.path, data, options));
        },
        update(r, data) {
          writes.push(() => updateDoc(r.path, data));
        },
        delete(r) {
          writes.push(() => store.delete(r.path));
        },
        async commit() {
          for (const w of writes) w();
        },
      };
    },
    async recursiveDelete(target) {
      for (const p of [...store.keys()]) {
        if (p === target.path || p.startsWith(`${target.path}/`)) store.delete(p);
      }
    },
    async runTransaction(fn) {
      const writes = [];
      const tx = {
        async get(r) {
          reads++;
          return snapshot(r.path);
        },
        create(r, data) {
          assert.equal(store.has(r.path), false, `create over existing ${r.path}`);
          writes.push(() => setDoc(r.path, data));
        },
        set(r, data, options) {
          writes.push(() => setDoc(r.path, data, options));
        },
        update(r, data) {
          assert.ok(store.has(r.path), `update of missing ${r.path}`);
          writes.push(() => updateDoc(r.path, data));
        },
      };
      const result = await fn(tx);
      for (const w of writes) w();
      return result;
    },
  };
}

module.exports = { fakeFirestore };
