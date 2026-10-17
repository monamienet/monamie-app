# Understanding CI: automatic deploy to internal testing

This document explains how the workflow
[`.github/workflows/deploy-play-internal.yml`](../../.github/workflows/deploy-play-internal.yml) works,
for readers who have never worked with CI. The workflow publishes the app to the Google Play
**internal testing** track on every merge into `main`.

The operational guide (initial setup, secrets and troubleshooting) is in
[publish-internal-testing.md](publish-internal-testing.md#automatic-release-ci).

---

## 1. Concepts

**CI/CD** (Continuous Integration / Continuous Delivery) means that a machine, not a person, runs the
repetitive steps of checking, building and publishing the code. It does this whenever something changes
in the repository. What used to be done by hand in the terminal (`flutter build appbundle`) and in the
browser (upload in the Play Console) becomes a "recipe" that runs on its own.

On GitHub, this tool is called **GitHub Actions**. Vocabulary:

| Term | What it is | In this project |
| :--- | :--- | :--- |
| **Workflow** | A YAML file in `.github/workflows/` describing *when* to run and *what* to do. GitHub picks it up automatically. | `deploy-play-internal.yml` |
| **Trigger** (`on:`) | The event that starts the workflow. | a push to `main`, or a manual click on "Run workflow" |
| **Runner** | The virtual machine GitHub starts to run the workflow. It starts **empty**: no Flutter, no Java, none of the files that are outside git. It is destroyed when the run ends. | `ubuntu-latest` (Linux) |
| **Job** | A group of steps that run in sequence on the same runner. | a single job, `deploy` |
| **Step** | One step of a job. Either a shell command (`run:`) or an **action** (`uses:`). | 9 steps |
| **Action** | A ready-made, reusable step published by someone, like a "function" you call. | `actions/checkout` downloads the code; `subosito/flutter-action` installs Flutter; `r0adkll/upload-google-play` uploads to Play |
| **Secret** | A sensitive value stored encrypted on GitHub. The workflow reads it with `${{ secrets.NAME }}`, and GitHub masks it in logs (shown as `***`). | the keystore, its passwords and the Play credential |
| **Environment** | A named "vault" (Settings → Environments) that groups secrets and can have rules, such as requiring manual approval before running. | `play-internal` |
| **Artifact** | A file produced on the runner that GitHub keeps for download after the runner is destroyed. | **not used**: the repository is public, so any signed-in GitHub user could download unreleased test builds. The Play Console already keeps every uploaded version. |

## 2. End-to-end flow

```
PR opened ──► PR approved ──► "Merge" on GitHub
                                    │
               the merge creates a new commit on main = "push to main" event
                                    │
                                    ▼
             GitHub Actions starts an empty Ubuntu runner
                                    │
   ┌────────────────────────────────┴─────────────────────────────────┐
   │ 1. downloads the code    2. installs Java 17                      │
   │ 3. installs Flutter      4. adjusts Gradle memory                 │
   │ 5. restores the keystore and key.properties                       │
   │ 6. fetches dependencies  7. runs the unit tests                   │
   │ 8. flutter build appbundle (signed, new versionCode)              │
   │ 9. uploads to Play (internal track)                               │
   └────────────────────────────────┬─────────────────────────────────┘
                                    ▼
         Internal testers get the update through the Play Store
```

If **any** step fails (a broken test, a missing secret, a compile error), the following steps do not
run and **nothing is sent to Play**. GitHub shows a ❌ on the commit and emails whoever pushed.

**Why "push to main" and not "PR accepted"?** GitHub has no "PR approved" event. Merging a PR always
produces a push to `main`, and that is the simplest and most reliable event to listen to. One consequence:
a **direct** push to `main`, without a PR, also triggers the deploy. The rules in
[AGENTS.md](../../AGENTS.md) already forbid direct pushes.

## 3. How to read the workflow file

### 3.1 YAML basics

YAML is just a way to write structured data, similar to JSON but without braces and quotes. The rules:

| Rule | Example | JSON equivalent |
| :--- | :--- | :--- |
| `key: value` defines a field | `name: Deploy` | `{"name": "Deploy"}` |
| **Indentation** (spaces) nests a field **inside** another | `on:`<br>`  push:` | `{"on": {"push": ...}}` |
| `-` at the start of a line is a **list item** | `steps:`<br>`  - run: a`<br>`  - run: b` | `{"steps": [{"run":"a"}, {"run":"b"}]}` |
| `[a, b]` is a list on a single line | `branches: [main]` | `{"branches": ["main"]}` |
| `#` starts a comment (ignored) | `# explains something` | — |

Two more notations appear in the file:
- `run: |`: the `|` means the indented lines below form **one multi-line text**, here a small shell script.
- `${{ ... }}`: not YAML, but a **GitHub expression**. Before running, GitHub replaces it with the real
  value. For example, `${{ secrets.ANDROID_KEY_ALIAS }}` becomes that secret's value and
  `${{ github.run_number }}` becomes the run number.

### 3.2 Keyword dictionary

The words on the left are **fixed**, defined by GitHub Actions. The values on the right are our choices.

| Keyword | What it does | Value in our file |
| :--- | :--- | :--- |
| `name` (top level) | Workflow name shown in the Actions tab. | `Deploy to Play (internal)` |
| `on` | Lists the **events** that trigger the workflow. | `push` and `workflow_dispatch` |
| `on.push.branches` | Limits the `push` event to certain branches. A push to another branch does not trigger it. | `[main]` |
| `on.workflow_dispatch` | Adds the "Run workflow" button for manual runs. Needs no value. | empty |
| `concurrency` | Controls **simultaneous** runs (section 3.4). | — |
| `jobs` | Lists the jobs. Each key inside it is a job **name** of our choosing. | one job named `deploy` |
| `runs-on` | The runner's operating system. | `ubuntu-latest` |
| `environment` | Which Environment (secret vault) the job uses. Without it, `secrets.X` is empty. | `play-internal` |
| `steps` | The **list** of steps, run top to bottom. Each `-` is one step. | 9 steps |
| `name` (inside a step) | Optional step label in the logs. | e.g. `Limit Gradle memory` |
| `uses` | The step **calls a ready-made action**, as `owner/repository@version`. | e.g. `actions/setup-java@v6` |
| `with` | The **parameters** passed to the action in `uses` (section 3.3). | e.g. `java-version: '17'` |
| `run` | The step **runs shell commands**, as in a terminal. | e.g. `flutter test test/unit` |
| `env` | **Environment variables** available to that step's `run` commands. | the passwords read from secrets |

A step uses **either** `uses` (+ `with`) **or** `run` (+ `env`, if needed). Both pairs play the same
role: what to run, and with which data.

### 3.3 `with`: an action's arguments

An action works like a **function** written by someone else. `uses` says **which function** to call,
and `with` passes the **arguments**:

```yaml
- uses: actions/setup-java@v6     # the function: "install Java", version 6 of the action
  with:                           # the arguments:
    distribution: temurin         #   which Java distribution (Temurin, Eclipse's free one)
    java-version: '17'            #   which Java version
```

In Dart, this would be something like `setupJava(distribution: 'temurin', javaVersion: '17')`.

**Each action defines** which arguments exist, listed in the README of its repository. For example,
`track` and `packageName` exist because `r0adkll/upload-google-play` accepts them. For
`actions/setup-java` they would mean nothing. `'17'` is quoted so YAML treats it as text, not a number.

### 3.4 `concurrency`: a queue of runs

```yaml
concurrency:
  group: play-internal          # any "queue name", chosen by us
  cancel-in-progress: false     # do not interrupt the run in progress
```

- **`group`** is a label. GitHub guarantees that, among all runs with the **same label**, only **one**
  runs at a time. The others wait in the queue. The text `play-internal` has no special meaning: it
  only has to be the same across runs that must not overlap.
- **`cancel-in-progress`** decides what happens to the run **already in progress** when a new one
  arrives:
  - `true`: the running one is **cancelled** and the new one takes its place;
  - `false`, our choice: the running one **finishes normally**, and the new one waits its turn.
    Cancelling a deploy mid-upload could leave a half-made release on Play.

A GitHub detail: the queue holds at most **one** pending run. If three merges arrive in a row, the
middle one is dropped and only the newest runs after the first. Nothing is lost, because the newest
`main` already contains the middle one's changes.

### 3.5 The steps, one by one

| # | Step | What it does and why |
| :--- | :--- | :--- |
| 1 | `actions/checkout` | The runner starts empty; this downloads the code of the commit that triggered the workflow. |
| 2 | `actions/setup-java` | Android's Gradle needs Java. The project compiles for JVM 17 ([build.gradle.kts](../../android/app/build.gradle.kts)). |
| 3 | `subosito/flutter-action` | Installs the **same** Flutter version used in development, so CI does not produce a different app. `cache: true` reuses the SDK and makes later runs faster. |
| 4 | `Limit Gradle memory` | [android/gradle.properties](../../android/gradle.properties) asks for 8 GB of RAM (`-Xmx8G`), more than the runner has. `~/.gradle/gradle.properties` takes precedence over the project file, so the limit is lowered on CI only. |
| 5 | `Restore release signing` | Restores the keystore and `android/key.properties`, which are not in git (section 4). First it checks that no secret is empty. |
| 6 | `flutter pub get` | Fetches the dependencies in `pubspec.yaml`. |
| 7 | `flutter test test/unit` | Runs the unit tests. If any fails, the deploy stops here. Integration tests are skipped because they need the Firebase emulators. |
| 8 | `flutter build appbundle` | Builds the release `.aab`, signed with the keystore from step 5 and with a new versionCode (section 5). |
| 9 | `r0adkll/upload-google-play` | Uploads the `.aab` to the `internal` track, authenticating with the service account (section 6). `status: completed` releases it straight to testers. |

## 4. How the keystore reaches the runner (why base64)

The runner only has what is in git, and the keystore and `key.properties` are left out on purpose: these
are real secrets. Whoever has the keystore and its passwords can sign app versions on MonAmieNet's behalf.

A GitHub secret, however, only stores **text**, and the keystore (`.jks`) is a **binary** file. The
common solution is **base64**: an encoding that turns any file into text made of letters and digits, and
that can be reversed without loss.

- **On the machine of whoever sets it up, once:** `base64 -w0 upload.jks` produces a text, which goes
  into the `ANDROID_KEYSTORE_B64` secret.
- **On the runner, every run:** `base64 -d` turns the text back into the original `.jks` file. It is
  written to a temporary folder (`$RUNNER_TEMP`) that is deleted with the runner.

`key.properties` does not need its own secret: it is assembled on the spot from the passwords and alias,
with `storeFile` pointing to the freshly decoded keystore.

### Two-layer fail-fast

A release build **never** falls back to the debug key, which would produce a bundle that Play rejects.
There are two safeguards:

1. **In the workflow:** step 5 names *which* GitHub secret is empty and stops the run.
2. **In Gradle:** the `validateReleaseSigning` task ([build.gradle.kts](../../android/app/build.gradle.kts))
   runs before **any** release build, on CI or on a local machine. It fails if `key.properties`, one of
   its properties or the keystore file is missing.

Debug builds (`flutter run`) are not affected and work without a keystore.

### What about `google_config.dart`?

[lib/app/config/google_config.dart](../../lib/app/config/google_config.dart) is versioned like any
other file because its values are **not secrets**: an OAuth client ID (public by design) and the groups
gateway address. Anything compiled into the app can be extracted from the binary by anyone. The gateway
is protected by the Google token (`Bearer`) the app sends with each request.

## 5. How the versionCode is set

Play requires each uploaded `.aab` to have a `versionCode` **greater** than every previous one. Before
CI, this was the number after the `+` in the `version:` of `pubspec.yaml`, bumped by hand.

GitHub gives each run of a workflow a counter, `GITHUB_RUN_NUMBER` (1, 2, 3...), that **only grows**.
The `--build-number` flag of `flutter build` overrides the number after the `+` without touching the
pubspec. So the 1st run produces versionCode **101**, the 2nd **102**, and so on. The `+100` guarantees
starting above the manual uploads already made.

- The **versionName** (`1.0.0`, what users see in the store) still comes from `pubspec.yaml`. Change
  it in a PR whenever you want.
- Failed runs also consume a number. This leaves "gaps" (101, 103...), which is fine: Play only
  requires the number to grow.
- ⚠️ **Do not rename the workflow file.** The counter belongs to the file. If it is renamed, the counter
  restarts at 1 and the upload fails with a duplicate versionCode.

## 6. How GitHub gets permission to publish on Play

To publish, GitHub has to authenticate with the Play Console without using a person's Google account.
That is what a **service account** is for: a "robot account" in Google Cloud with a credential file
(JSON). In the Play Console, this account gets permission **only** to release to the app's testing
tracks. The JSON is stored in the `PLAY_SERVICE_ACCOUNT_JSON` secret, and the
`r0adkll/upload-google-play` action uses it to call the Play API.

We use this action instead of **fastlane**, another popular mobile deploy tool, because it only does the
upload, needs no Ruby install and fits in a few lines of YAML.
