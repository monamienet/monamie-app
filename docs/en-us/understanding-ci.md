# Understanding CI: automatic deploy to internal testing

This document explains how the workflow
[`.github/workflows/deploy-play-internal.yml`](../../.github/workflows/deploy-play-internal.yml) works,
for readers who have never worked with CI. The workflow publishes the app to the Google Play
**internal testing** track on every merge into `main` that changes the app.

> **Summary to explain to someone:** on every merge into `main` that changes the app, GitHub starts a clean machine, runs the
> tests, builds the `.aab` signed with the keystore stored in the secrets and uploads it to internal
> testing. To talk to Google Play it uses no password or key: it trades a temporary GitHub token for a
> temporary token of a dedicated service account (Workload Identity Federation).

The operational guide (setup, checks and troubleshooting) is in
[publish-internal-testing.md](publish-internal-testing.md). The CI setup corresponds to steps A2 to A6, C4 and C9 to C12.

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
| **Trigger** (`on:`) | The event that starts the workflow. | a push to `main` that changes app files, or a manual click on "Run workflow" |
| **Runner** | The virtual machine GitHub starts to run the workflow. It starts **empty**: no Flutter, no Java, none of the files that are outside git. It is destroyed when the run ends. | `ubuntu-latest` (Linux) |
| **Job** | A group of steps that run in sequence on the same runner. | a single job, `deploy` |
| **Step** | One step of a job. Either a shell command (`run:`) or an **action** (`uses:`). | 10 steps |
| **Action** | A ready-made, reusable step published by someone, like a "function" you call. | `actions/checkout` downloads the code; `subosito/flutter-action` installs Flutter; `r0adkll/upload-google-play` uploads to Play |
| **Secret** | A sensitive value stored encrypted on GitHub. The workflow reads it with `${{ secrets.NAME }}`, and GitHub masks it in logs (shown as `***`). | the keystore and its passwords. The Play credential is **not** a secret: authentication is keyless (section 6) |
| **Environment** | A named "vault" (Settings → Environments) that groups secrets and can have rules, such as requiring manual approval before running. | `play-internal` |
| **Artifact** | A file produced on the runner that GitHub keeps for download after the runner is destroyed. | **not used**: the repository is public, so any signed-in GitHub user could download unreleased test builds. The Play Console already keeps every uploaded version. |

## 2. End-to-end flow

```
PR opened ──► PR approved ──► "Merge" on GitHub
                                    │
               the merge creates a new commit on main = "push to main" event
                                    │
                 did the push touch any app file? ── no ──► nothing runs
                                    │ yes
                                    ▼
             GitHub Actions starts an empty Ubuntu runner
                                    │
   ┌────────────────────────────────┴─────────────────────────────────┐
   │ 1. downloads the code    2. installs Java 17                      │
   │ 3. installs Flutter      4. adjusts Gradle memory                 │
   │ 5. restores the keystore and key.properties                       │
   │ 6. fetches dependencies  7. runs the unit tests                   │
   │ 8. installs the Firebase CLI                                      │
   │ 9. authenticates with Google: read-only config account            │
   │ 10. flutter build appbundle (fetches google-services.json,        │
   │     signs, new versionCode)                                       │
   │ 11. authenticates with Google: publisher account (WIF)            │
   │ 12. uploads to Play (internal track)                              │
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

### Which changes trigger the deploy

Not every merge changes the app. Editing a `.md`, a skill in `.agents/`, the Cloud Functions or the iOS
code produces an `.aab` **identical** to the previous one. Publishing it would only waste CI minutes and
send testers an empty "update". That is why the trigger has a `paths` filter: the workflow only runs if
the push changes at least one of these paths, which are the inputs of the Android build:

| Path | Why it goes into the `.aab` |
| :--- | :--- |
| `lib/**` | the Dart code |
| `android/**` | Gradle, manifest |
| `assets/**` | images declared in `pubspec.yaml` |
| `tool/**` | the partner tool: the build runs `tool/partner.dart firebase <id>` to fetch `google-services.json` (section 6) |
| `pubspec.yaml`, `pubspec.lock` | dependencies and the asset list |
| `.github/workflows/deploy-play-internal.yml` | the pipeline itself: if it changes, it must run to prove it still works |

`**` means "any file, in any subfolder". For a PR merge, GitHub considers **all** files the PR changed:
a PR that touches `AGENTS.md` **and** `lib/` deploys as usual.

**Why list what goes in (`paths`) instead of what stays out (`paths-ignore`)?** The build inputs are few
and rarely change. What does **not** go into the app is a long list (docs, skills, other platforms,
Firebase backend) that grows with every new tool. A list of exclusions would need constant upkeep, and
every omission would become a useless build.

The cost of this choice is the opposite mistake. If someone adds a new build input outside the list (an
`l10n.yaml`, a `fonts/` folder, a local package in `packages/`), changes to it alone will **not** deploy.
In that case:
1. add the path to the workflow's `paths` list (a comment in the file is a reminder);
2. to publish right away, use the **Run workflow** button, which ignores the filter.

Changes only to `test/` do not deploy either, since they do not change the app. One consequence: tests
currently run only inside the deploy, so a PR that touches **only** tests is not checked by any CI. Run
`flutter test` locally in those cases.

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
| `on.push.paths` | Limits the `push` event to pushes that change certain files. If no changed file matches the list, the workflow does not run. | the Android build inputs (section 2) |
| `on.workflow_dispatch` | Adds the "Run workflow" button for manual runs. Needs no value and ignores the `paths` filter. | empty |
| `concurrency` | Controls **simultaneous** runs (section 3.4). | — |
| `jobs` | Lists the jobs. Each key inside it is a job **name** of our choosing. | one job named `deploy` |
| `runs-on` | The runner's operating system. | `ubuntu-latest` |
| `environment` | Which Environment (secret vault) the job uses. Without it, `secrets.X` is empty. | `play-internal` |
| `permissions` | What the job's automatic token may do. Anything not listed is forbidden. | `contents: read` (read the code) and `id-token: write` (request the OIDC token from section 6) |
| `steps` | The **list** of steps, run top to bottom. Each `-` is one step. | 10 steps |
| `name` (inside a step) | Optional step label in the logs. | e.g. `Limit Gradle memory` |
| `id` (inside a step) | A nickname for the step. Later steps read its outputs with `${{ steps.<id>.outputs.<name> }}`. | `auth`: the upload reads `steps.auth.outputs.credentials_file_path` |
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
| 8 | `Install Firebase CLI` | Installs a pinned `firebase-tools` version. The build uses the CLI to fetch the central project's Firebase config. |
| 9 | `google-github-actions/auth` (`auth-config`) | Trades GitHub's OIDC token for temporary credentials of a service account that **only reads** Firebase app configs (section 6). |
| 10 | `flutter build appbundle` | Builds the release `.aab` of the single app `org.monamienet.app`, signed with the keystore from step 5 and with a new versionCode (section 5). Before compiling, Gradle fetches the central project's `google-services.json` with the credentials from step 9. Partners are bound at runtime, so no partner is chosen here. |
| 11 | `google-github-actions/auth` (`auth`) | Trades GitHub's OIDC token for temporary credentials of the publisher service account, with no key (section 6). |
| 12 | `r0adkll/upload-google-play` | Uploads the `.aab` to the `internal` track with the credentials from step 11. `status: completed` releases it straight to testers. |

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
other file because its values are **not secrets**: the groups gateway address and paths. The OAuth client
IDs are no longer in the code: they come from the central project's config, fetched at build time. Anything compiled into the app can be extracted from the binary by anyone. The gateway
is protected by the Google token (`Bearer`) the app sends with each request.

## 5. How the versionCode is set

Play requires each uploaded `.aab` to have a `versionCode` **greater** than every previous one. Before
CI, this was the number after the `+` in the `version:` of `pubspec.yaml`, bumped by hand.

GitHub gives each run of a workflow a counter, `GITHUB_RUN_NUMBER` (1, 2, 3...), that **only grows**.
The `--build-number` flag of `flutter build` overrides the number after the `+` without touching the
pubspec. So the 1st run produces versionCode **101**, the 2nd **102**, and so on. The `+100` reserves
the numbers below 101 for manual uploads, such as an app's first release.

- The **versionName** (`1.0.0`, what users see in the store) still comes from `pubspec.yaml`. Change
  it in a PR whenever you want.
- Pushes filtered out by `paths` (section 2) do **not** consume a number: the workflow never runs.
- Failed runs also consume a number. This leaves "gaps" (101, 103...), which is fine: Play only
  requires the number to grow.
- ⚠️ **Do not rename the workflow file.** The counter belongs to the file. If it is renamed, the counter
  restarts at 1 and the upload fails with a duplicate versionCode.

## 6. How GitHub gets permission to publish on Play (keyless)

To publish, GitHub has to authenticate with the Play API without using a person's Google account. The
identity the API sees is a **service account**: a "robot account" in Google Cloud. The most common approach
would be to create a JSON key for it and store it as a secret, but **we use no key**: a key never expires
and, if leaked, grants access until someone revokes it. Google recommends avoiding keys whenever possible.

We use **Workload Identity Federation (WIF)**, where GitHub trades a temporary "badge" for a Google token
that is temporary too:

```
 GitHub Actions                          Google Cloud (ci-cd-management project)
 ──────────────                          ───────────────────────────────────────
 1. the job, in the play-internal
    environment, asks GitHub for an
    OIDC token: "I am the repo
    monamienet/monamie-app,
    environment play-internal"   ──────► 2. the "github" provider checks: was the
                                            token signed by GitHub? does it come
                                            from the organization with ID 336690459?
                                         3. does the wlif-monamie-app-play service
                                            account accept this subject?
 4. gets an access token for the ◄────── yes: returns a token valid for ~1 hour
    service account
 5. calls the Play API with it   ──────► Play Console: was this account invited,
                                         and can it release to the app's testing tracks?
```

| Term | What it is | In this project |
| :--- | :--- | :--- |
| **OIDC token** | A "badge" signed by GitHub describing the job: repository, branch, environment. The job can only request it with the `id-token: write` permission. | issued on every run |
| **Workload identity pool** | Groups the external (non-Google) identities accepted in the project. | `github-actions` |
| **Provider** | States which issuer the pool trusts and which tokens it accepts, through an *attribute condition*. | `github`: only tokens from the `monamienet` organization |
| **Subject** | The token field that identifies the job. For a job with an environment, it looks like `repo:<org>@<org id>/<repo>@<repo id>:environment:<name>`. The IDs are there because the repository uses GitHub's *immutable* format. | `repo:monamienet@336690459/monamie-app@1407450217:environment:play-internal` |
| **Impersonation** | Temporarily taking on a service account's identity. Who may do it is defined by the `roles/iam.workloadIdentityUser` role on the service account itself. | only the subject above |
| **Service account** | The identity the Play API sees. Its permissions live in the Play Console, not in Google Cloud. | `wlif-monamie-app-play@ci-cd-management.iam.gserviceaccount.com` |

In the workflow, this means two changes: `permissions: id-token: write` on the job and the
`google-github-actions/auth` step. That step writes a temporary credential file, and its path
(`steps.auth.outputs.credentials_file_path`) is passed to the upload action.

### Three layers decide who can publish

1. **Provider:** only accepts tokens from the `monamienet` organization. The condition uses the numeric ID
   (`336690459`), not the name, because a deleted organization's name can be registered by someone else,
   while the ID is never reused.
2. **Service account permission:** only the subject `repo:monamienet@336690459/monamie-app@1407450217:environment:play-internal`
   can impersonate it. Other repositories in the organization, or jobs without that environment, are refused.
   Because the subject includes the IDs, a repository recreated with the same name is refused too.
3. **`play-internal` environment:** GitHub only lets jobs from the `main` branch use this environment.

The provider ID and the service account email are written in the workflow itself, and that is fine:
without an OIDC token issued by GitHub for this repository and environment, they are useless.

### Why a dedicated service account

`wlif-monamie-app-play` exists only for this pipeline and has no Google Cloud roles. Its only permission
is the Play Console one to release to testing tracks. This follows Google's official recommendations:

- [Best practices for using service accounts in deployment pipelines](https://docs.cloud.google.com/iam/docs/best-practices-for-using-service-accounts-in-deployment-pipelines):
  *"Use dedicated service accounts per deployment pipeline"*, keeping a 1:1 relationship between pipelines
  and service accounts, and *"Use Workload Identity Federation whenever possible"*.
- [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts):
  *"Create single-purpose service accounts"*. Sharing an account across applications makes it unclear
  whether it can be decommissioned, lets its permissions grow, and makes audit logs ambiguous. The `wlif-`
  prefix follows the same guide's naming convention for accounts used by Workload Identity Federation.
- [Best practices for using Workload Identity Federation](https://docs.cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation):
  use an attribute condition with multi-tenant providers such as GitHub, and attributes that cannot be reused.

### Two service accounts: one reads the config, the other publishes

The build also talks to Google. The app's `google-services.json` is not versioned: it holds API keys, and
a copy in the repository would drift from the source of truth, the central Firebase project
(`monamienet-app`). So Gradle fetches the file from that project when it is missing. The workflow
authenticates **twice**, with the same provider and the same subject:

| Step | Service account | What it can do | When |
| :--- | :--- | :--- | :--- |
| 9 (`auth-config`) | `wlif-monamie-app-config` | list Firebase apps and read their config (custom role `firebaseAppConfigReader`: `firebase.clients.list` and `firebase.clients.get`), only on `monamienet-app`, where the role is bound | before the build |
| 11 (`auth`) | `wlif-monamie-app-play` | release to Play testing tracks | after the build |

The order matters. The build runs third-party code (Gradle plugins, pub packages), and every step can
reach the credentials already created on the runner. Because the publisher account is only authenticated
after the build, that code never holds the Play credential. With the other one, the most it can do is read
configs that ship inside every published APK anyway. The predefined `roles/firebase.viewer` is not used
because it also reads product data, such as the teams' location history in Firestore.

The Firebase CLI accepts the WIF credentials: with no `firebase login`, it uses Google's *Application
Default Credentials*, which the auth step sets up in the `GOOGLE_APPLICATION_CREDENTIALS` variable. Step 11
overwrites that variable, but only after the build.

### Why this upload action

We use `r0adkll/upload-google-play` instead of **fastlane**, another popular mobile deploy tool, because it
only does the upload, needs no Ruby install and accepts Workload Identity Federation credentials.
