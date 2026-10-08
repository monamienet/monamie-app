const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
admin.initializeApp();

// Parâmetros por instância (functions/.env.<projectId>): host do
// workspace-groups-gateway e e-mail do grupo raiz do cliente.
const BACKEND_HOST = defineString("GROUPS_GATEWAY_HOST");
const ROOT_GROUP = defineString("ROOT_GROUP_EMAIL");

/**
 * Callable Cloud Function que sincroniza os Custom Claims do Firebase Auth
 * com os papéis do usuário nos subgrupos do grupo raiz do cliente
 * (via workspace-groups-gateway / Google Workspace).
 *
 * Os claims resultantes contêm um mapa `harpia_roles` que associa cada
 * grupo a um role efetivo (MEMBER, MANAGER, OWNER ou METAUSER).
 *
 * Invocada pelo app Flutter após o login e ao atualizar grupos.
 */
exports.syncHarpiaClaims = onCall({ invoker: "public" }, async (request) => {
  console.log(
    `[syncHarpiaClaims] Invocado. Auth: ${JSON.stringify(request.auth)}`
  );
  // 1. Validar autenticação (Callable já faz isso, mas é boa prática checar)
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Autenticação necessária.");
  }

  const uid = request.auth.uid;
  const email = request.auth.token.email;
  if (!email) {
    throw new HttpsError(
      "failed-precondition",
      "Email não disponível no token."
    );
  }

  // 2. O idToken bruto é passado como parâmetro pelo app para que a CF
  //    possa repassá-lo ao backend intermediário (que espera Bearer token).
  const idToken = request.data.idToken;
  if (!idToken) {
    throw new HttpsError("invalid-argument", "idToken é obrigatório.");
  }

  // 3. Computar roles efetivos via travessia recursiva da árvore de grupos
  const roles = {};
  await computeRoles(
    idToken,
    email,
    ROOT_GROUP.value(),
    roles,
    /* isAncestorMember= */ false
  );

  // 4. Definir Custom Claims
  const claims = { harpia_roles: roles };
  await getAuth().setCustomUserClaims(uid, claims);

  return { harpia_roles: roles };
});

/**
 * Percorre recursivamente a árvore de grupos a partir de `groupEmail`,
 * preenchendo o mapa `roles` com o role efetivo do usuário `userEmail`
 * em cada grupo encontrado.
 *
 * Os grupos formam uma árvore n-ária onde:
 * - O grupo raiz é a raiz da árvore.
 * - Os subgrupos (entidades com type=GROUP) são os filhos de cada nó.
 *
 * Metausuário de um grupo G é um usuário de qualquer ancestral de G na árvore.
 *
 * Regra de precedência: role direto (MEMBER/MANAGER/OWNER) prevalece sobre
 * status de METAUSER herdado de um ancestral.
 *
 * @param {string}  idToken           - Firebase ID Token para autenticar com o backend
 * @param {string}  userEmail         - Email do usuário cujos roles estão sendo computados
 * @param {string}  groupEmail        - Email do grupo atual sendo processado
 * @param {Object}  roles             - Mapa acumulador {groupEmail → role} (mutado in-place)
 * @param {boolean} isAncestorMember  - true se o usuário é membro de algum ancestral
 *                                      deste nó na árvore (determina status de METAUSER)
 */
async function computeRoles(
  idToken,
  userEmail,
  groupEmail,
  roles,
  isAncestorMember
) {
  const entities = await fetchGroupEntities(idToken, groupEmail);

  // 1. Verificar se o usuário é membro DIRETO deste grupo
  const directMember = entities.find(
    (e) =>
      e.type === "USER" &&
      e.email.toLowerCase() === userEmail.toLowerCase()
  );

  // 2. Determinar o role efetivo NESTE grupo
  //    - Role direto (MEMBER/MANAGER/OWNER) tem precedência
  //    - Se não há role direto mas é ancestorMember, é METAUSER
  //    - O grupo raiz em si NÃO é registrado nos claims (é estrutural)
  if (groupEmail !== ROOT_GROUP.value()) {
    if (directMember) {
      roles[groupEmail] = directMember.role; // "MEMBER", "MANAGER", ou "OWNER"
    } else if (isAncestorMember) {
      roles[groupEmail] = "METAUSER";
    }
  }

  // 3. Para os filhos (subgrupos), propagar a flag isAncestorMember
  //    Se o usuário é membro direto DESTE nó, seus descendentes o terão
  //    como metausuário.
  const userIsMemberOfThisNode = !!directMember;
  const propagateAncestor = isAncestorMember || userIsMemberOfThisNode;

  const subgroups = entities.filter(
    (e) =>
      e.type === "GROUP" &&
      !e.email.startsWith("space/")
  );

  for (const sg of subgroups) {
    await computeRoles(
      idToken,
      userEmail,
      sg.email,
      roles,
      propagateAncestor
    );
  }
}

/**
 * Busca as entidades (membros + subgrupos) de um grupo via backend intermediário.
 *
 * @param {string} idToken    - Firebase ID Token para autenticação
 * @param {string} groupEmail - Email do grupo a consultar
 * @returns {Array<{type: string, email: string, role: string, name?: string}>}
 */
async function fetchGroupEntities(idToken, groupEmail) {
  const url = `https://${BACKEND_HOST.value()}/members?email=${encodeURIComponent(
    groupEmail
  )}`;
  const response = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${idToken}`,
    },
  });

  if (!response.ok) {
    throw new HttpsError(
      "internal",
      `Erro ao buscar membros de ${groupEmail}: ${response.status}`
    );
  }

  const data = await response.json();
  return data.members || [];
}
