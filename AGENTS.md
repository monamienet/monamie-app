# AGENTS.md

## Project Overview

This application is maintained by the company MonAmieNet and provides clients (organizations) services for tracking, coordination and comunication of teams.

## Business Architecture

MonAmie publishes a **single app** on its Google Developer Account: `org.monamienet.app`, named "MonAmie" (launcher, Play listing and native splash are the same for everyone). Each organization (client) is on one of two **plans** (`plan` in the central registry `organizations/{id}`):
- **Standard**: its own Firebase project `monamienet-<id>`, on the organization's own billing account;
- **Community** (free): the shared project `monamienet-community`, owned and paid by MonAmieNet, restricted to the *Economia* tracking preset (one position every 15 minutes at most, enforced by the rules through `organizations/{id}/config/plan.minIntervalMinutes`). The central project and the Community project stay separate projects (Auth, claims, IAM and quotas are per project).

On both plans **every organization's data lives under `organizations/{organizationId}/…`** of its project: `config/branding` (publicly readable), `config/plan`, `config/tracking` (the administrators' period and radius, followed live by the background service; the map's one freshness threshold, the validity, is fixed at 12 minutes, see `docs/pt-br/compartilhamento.md`), `positions/{email}` (a person's last position: `name`, `lat`, `lng`, `capturedAt` on the device clock, `receivedAt` on the server clock, `isPublishing`, `groupId` = the team group's e-mail for now) with `trail/{pointId}` and `trailDays/{yyyy-mm-dd}` (a per-day summary, `lastAt` and `pointCount`, written in the same batch as each position, so the history calendar reads at most one document per person and day). A Standard project is simply a project holding one organization, so code, rules and tests are the same for both plans; no path is ever read at the root. The rules scope every match by organization (the `organizations` claim) and test cross-organization access. Collection and field names live in one place per codebase: `FirestorePaths` (`lib/app/data/firebase/firestore_paths.dart`, also used by `tool/`) and `firestore_paths.js` in `functions/` and `central/functions/`; use them instead of string literals.

The app binds the organization **at runtime**, after Google sign-in, never at build time:
1. Google sign-in goes through the central MonAmie project `monamienet-app` (the `[DEFAULT]` Firebase app). Only one OAuth client may exist per package + SHA-1, so it lives there, and every organization project allows the central web client under "Allowed client IDs".
2. The central `resolveOrganizations` function (`central/functions/`) reads the user's groups and derives their organizations from the group names (see below), keeping those whose entry in the central registry `organizations/{id}` has a `status` the app shows. The status follows a fixed lifecycle (`reserved` → `awaiting_billing`/`provisioning` → `active`, plus `failed`, `migrating` and `deleting`) written only by the central functions; its timed exits delete the organization's project and registry entry and retire the id forever in `retiredOrganizationIds/{id}` (see `docs/en-us/white-label.md`, *Organization status*). Organizations are created in the app (`createOrganization`; the creator becomes the owner and first administrator) and an account is deleted in the app with 30 days to cancel (`accountDeletions/{email}`; an owner's organization goes to `deleting` with it); see the guide's sections 11 and 12.
3. The app binds the chosen organization (`OrganizationSession`): its Firebase project (a named app `organization-<id>`), its root group and its branding, all together, and remembers the binding on the device (`SharedPreferences`) until sign-out or removal from the organization's groups.

Where each value lives:
- **Organization's choice**: name (required) and a catalog `themeId` in `organizations/<id>/config/branding`, plus an optional logo, one square 512 px PNG at `organizations/<id>/logo.png` in the organization's Cloud Storage (converted on an administrator's device from any format; never an SVG). Administrators change them in the app (*Aparência*, through the `setBranding` function, which validates the theme against the central catalog); `dart run tool/organization.dart publish <id> --name … --theme …` sets name and theme for organizations onboarded by hand.
- **MonAmie's choice**: the organization's `status` in `organizations/{id}` and the **theme catalog** `themes/{id}` (`name`, `primary`, `dark`, `light`, `onPrimary`, `onDark`, `order`, `active`), both in the central project. Organizations pick a theme, never free colors; an unknown or missing `themeId` falls back to Grafite, and a retired theme (`active: false`) still resolves. The catalog is seeded with `dart run tool/organization.dart themes` and is publicly readable.
- **Derived by rule**, never stored: project `monamienet-<id>` (Standard) or `monamienet-community` (Community, from `plan`), root group `<id>00@monamienet.org`, organization id from a group name.
- **Names never side by side**: "MonAmie" appears alone on MonAmie's own screens (launcher, Play listing, splash, sign-in, organization picker, organization creation); once an organization is bound, the app shows only the organization's name. `publish` refuses an organization name starting with "MonAmie ".
- **Owned by another system**, fetched, never versioned: the central `google-services.json` (build time, `tool/organization.dart firebase`) and each organization's Firebase options (runtime, `resolveOrganizations`).

Rules that come from the plugins' source code: never `delete()` an organization `FirebaseApp` (cloud_firestore caches instances per app name forever); the organization app is created natively in `MonAmieApplication.kt` so the UI and the tracking service engines never race to create it; the binding lives in `SharedPreferences`, not Hive, because two isolates read it.

Onboarding an organization needs no app release: see `docs/en-us/white-label.md`. CI only ships the app: Cloud Functions and rules are deployed by hand, `central/` once to `monamienet-app` and `functions/` + `firestore.rules` to every organization project.

### Organizations, Groups and Users

> **Migration in progress (#159).** Groups and roles are moving from Google Groups to Firestore membership documents, and every Firestore name to English (done in phase 2: `partner` → `organization`, `usuarios` → `positions`). The approved plan, with one issue per phase, is [docs/pt-br/migracao-grupos-firestore.md](docs/pt-br/migracao-grupos-firestore.md). This file keeps describing the system as it is today; each phase updates the part it changes in the same PR. Read the plan before touching groups, roles, invites, positions or Firestore paths.

Groups in the monamienet.org Google Workspace have **three levels**, and **everyone is a plain `MEMBER`**: what a person can do comes from *which* group they are in, never from the `MANAGER`/`OWNER` roles (those carry admin powers in groups.google.com, so nobody outside MonAmieNet gets them).

```
rotasul00@      level 0: root group; its members are the administrators
├─ rotasul01@   level 1: a team (01–99); holds the team's display name, no direct members
│  ├─ rotasul01r@   level 2: watch the team's map
│  └─ rotasul01w@   level 2: share their own location in the team
└─ rotasul13@ …
```

- **Parsing**: a group address is split by `^([a-z]+)(\d{2})([rw])?$` (before `@monamienet.org`) into organization id, team number and leaf. This works because **organization ids are lowercase letters only** (at least three); `app` and `community` are reserved. `<id>00r`, `<id>00w`, single-digit teams and `rw` leaves never exist. The parser has twins in `functions/group_address.js`, `central/functions/group_address.js` and `lib/app/config/organization/group_address.dart` (also used by `tool/`).
- **Capabilities** (custom claims set by the organization's `syncClaims` from the person's **direct** groups, one gateway call, no tree walk): `share: [teamKey]` from `<id>NNw`, `watch: [teamKey]` from `<id>NNr`, `admin: [organizationId]` from `<id>00`, where a team key is `<id>NN`. Administrators watch every team of their organization. "Both" means being in both leaves. A direct member of a level-1 group gets nothing (logged as a configuration error). `firestore.rules` checks these claims: reading positions needs `watch` in the team (or administering the organization), writing one's own position needs `share` in it, and a field-only person reads only their own document.
- **Administrators** (*administradores*) are the direct members of the root group, and **only** they: administration powers (teams, invites, appearance, tracking settings, seeing every team) come from Google Groups, never from Firebase. A root group may have several. The app (`admin` claim), the rules and the central team functions (a Cloud Identity membership lookup) all ask the same question: is this person a direct member of `<id>00@`?
- **The owner** (*titular* in the app, a gender-neutral word) is the person who created the organization, recorded in Firebase as `ownerEmail` in the central registry `organizations/{id}`. Being the owner grants no powers by itself; it only means that deleting their account deletes the organization (confirmed by typing its id), and `resolveOrganizations` tells the app so (`owner`). The creator is also added to the root group, so they start as its first administrator, and cannot leave (for now). A non-owner administrator who deletes their account leaves the root group like any team.
- **Changing a role** = joining or leaving a leaf; **removing someone from a team** = leaving both leaves. Organizations created before this model are moved with `dart run tool/organization.dart migrate-groups <id>` (prints the plan; `--apply` runs it).

### Client Onboarding Data (Google Drive via `rclone`)

Clients submit their instance identity through an onboarding Google Form. The answers and uploaded files live in MonAmieNet's **"Onboarding de parceiros"** shared drive. When asked to retrieve client data, use `rclone` with the `monamie:` remote; do not use the claude.ai Google Drive connector (it cannot be bound to the monamienet.org account).

- **Remote**: `monamie:` — Google Drive, `scope = drive.readonly`, bound to the "Onboarding de parceiros" shared drive and authenticated with a monamienet.org account. Check it exists with `rclone listremotes`.
- **Layout**:
    - `Respostas.xlsx` — native Google Sheet with the form answers (one row per submission: app name, alternative name, suggested identifier, primary/secondary colors, logo file names).
    - `Envios/<YYYY-MM-DD HHMM> – MonAmie <instance_name>/` — files uploaded with each submission (e.g. `logo-sem-texto.svg` for the app icon, `logo-com-texto.svg` for the login screen).
- **Commands**:
    - List everything: `rclone lsjson -R monamie:`
    - Export the answers: `rclone copy monamie: <dir> --include "Respostas.*" --drive-export-formats csv` (exports the first sheet as `Respostas.csv`).
    - Download a submission: `rclone copy "monamie:Envios/<submission folder>" <dir>`
- **Handling rules**:
    - Download into a session scratch/temp directory, never into the repository. The answers contain client personal data (e.g. contact e-mail); only copy the fields the task needs into the codebase.
    - Never print or read `~/.config/rclone/rclone.conf` in full; it stores the OAuth token. `rclone config show monamie` is fine only when filtered to non-secret keys (`type`, `scope`, `team_drive`).
    - Read-only access: never request a broader scope or try to modify the drive.
- **Missing remote**: `rclone config` is interactive, so the human must run it (`n` → name `monamie` → `drive` → empty client id/secret → scope `drive.readonly` → browser login with the monamienet.org account → Shared Drive `y` → "Onboarding de parceiros"). If Google shows a generic "Error 400 … malformed" page, open the `http://127.0.0.1:53682/auth?...` link printed by rclone in a private window signed in only to the monamienet.org account.


## Frontend & Architectural Best Practices

### Asynchronous Actions & Visual Feedback
- **Immediate Visual Feedback**: Any interactive trigger initiating an asynchronous operation (background services, location hardware, authentication, remote queries) must immediately render a visible pending/loading state (e.g., progress spinner, transitional colors).
- **Debouncing & Reentrancy Guards**: Disable interactive triggers (`onPressed: null`) and protect controllers with reentrancy guard clauses (`if (isLoading.value) return;`) while operations are in flight to prevent concurrent executions and race conditions.
- **Guaranteed State Reset**: Always wrap asynchronous processes in `try ... finally` blocks to guarantee the loading state is reset on early returns or exceptions, preventing UI freezes.

### Contract & Interface Segregation (SOLID)
- **Dedicated Contract Files**: When creating abstract interfaces/contracts for widgets or controllers (e.g., to support dependency injection and testability), place the interface in its own dedicated file rather than inside the concrete implementation file.
- **Avoid Transitive Bloat**: Pure UI components and widget tests must only depend on lightweight contracts, avoiding transitive dependencies on heavy concrete controllers that import background services, map rendering, or native hardware plugins.

### Hardware & Sensor Operations UX
- **User-Facing Transparency**: Never silently swallow hardware or sensor timeouts (e.g., GPS satellite fix) with developer-only `debugPrint`. When a service starts but sensor calibration is pending, provide transparent, non-blocking user feedback (e.g., an informative SnackBar or status banner) clarifying that the service is running while satellites/hardware sync.
- **Defensive Timeouts**: Guard platform hardware and sensor calls (e.g., `Geolocator.getCurrentPosition()`) with sensible timeouts (e.g., 5 seconds) and `try/catch` blocks to prevent freezing or unhandled crashes during cold starts or weak-signal environments.


## Testing

Follow `.agents/rules/AI_UNIT_TESTING_GUIDELINES.md`: test only code that makes decisions, never configuration files read with regex, and keep `flutter test test/unit -j 2` under two minutes on an 8 GB laptop. Remove a feature's tests in the same commit that removes the feature.

Security rules are tested for real against the emulators in `test/rules/` (Node, `@firebase/rules-unit-testing`): `cd test/rules && npm ci && nice -n 10 npm test`. Each test file uses its own `demo-*` project id so they share one emulator run.

## Resource Limits on Dev Machines

Dev laptops have 8 GB of RAM shared with the IDE and a browser. Run heavy commands at low priority and low parallelism: `nice -n 15 flutter test test/unit -j 2`, and Gradle with at most two workers (`org.gradle.workers.max=2` in `~/.gradle/gradle.properties`; `flutter build` gives no flag for it). The project caps the Gradle heap at 2 GB. Avoid running more than one build or test process at a time.


## Running the Web App Locally

Follow `docs/en-us/run-web-locally.md`. Serve `build/web` on `http://localhost:5000`: it is the only local origin the OAuth web client accepts for Google sign-in. For unattended checks, capture the screenshot through CDP after Flutter paints, never with `--screenshot`.


## Git Workflow

- **Keep local `main` in sync**: Local `main` is a mirror of `origin/main` and must never receive direct commits. Before starting a task, fast-forward it: `git fetch origin main:main` from any other branch, or `git pull --ff-only` when `main` is checked out. If the fast-forward fails, local `main` has diverged; stop and report it instead of merging or resetting.
- **One branch per task**: Whenever a new task is assigned, create its issue first (see *Tracking Work in Issues*), then a new branch from the freshly synced `main` before making any changes (`git switch -c <type>/<short-description> main`). Never work directly on `main` or reuse a branch from a previous task.
- **Branch naming**: Prefix the branch with the change type, matching the commit convention (e.g. `feat/`, `fix/`, `chore/`, `docs/`, `build/`).
- **Pull request after human approval**: When the task is finished, wait for explicit human approval before opening a pull request to merge the branch into `main`. Do not open the PR, or merge it, without that approval. The PR description closes the task's issue (`Closes #<n>`).
- **GitHub interactions via MCP**: Interact with GitHub (pull requests, issues, reviews, projects, comments, etc.) preferably through the GitHub MCP server tools. Fall back to the `gh` CLI only when the GitHub MCP server is unavailable in the session or does not support the required operation.

## Releases

Every merge to `main` that touches the app is a release on the Play internal track; a human promotes chosen ones to closed testing with `promote-play-closed.yml` (walkthrough: `docs/en-us/publish-internal-testing.md`, section D).
- **versionName**: computed by the deploy from the Conventional Commits that touch the app since the last `v*` tag (`.github/scripts/next-version.sh`): `feat:` bumps the minor, `fix:` the patch; the deploy then tags the commit. Never edit `version:` in `pubspec.yaml`. **Never** use `!` or a `BREAKING CHANGE:` footer; the major version changes only when the human asks, through a commit with the footer `Release-As: X.0.0`.
- **Release notes**: every PR with a change visible to people using the app (`feat:` or `fix:` touching `lib/`, `android/` or `assets/`) rewrites `distribution/whatsnew/whatsnew-pt-BR` and `whatsnew-en-US`, the same text in both languages:
    - they cover **everything** visible since the `play-closed` tag, the last version promoted to closed testing (`git log play-closed..HEAD`; with no such tag, the whole app), because closed testers may skip versions; merge the new change into what is already there and drop what `play-closed` already contains;
    - write for end users: no technical terms, commit types, screen code names or issue numbers; at most 500 characters per file (`wc -m`), Play's limit; when space runs out, keep the most important changes;
    - the deploy fails before uploading if the files are missing, too long, or not updated since the last `v*` tag while the app changed (`.github/scripts/check-release-notes.sh`).

## Tracking Work in Issues

- **One issue per request, before starting**: Whenever the human asks for anything that changes the repository (code, tests, docs, configuration, rule files, this file), create its GitHub issue **before** making any change, then do the work. Two exceptions, where no new issue is created: a follow-up of a task that already has an issue (adjusting its open PR, answering review comments, fixing its CI) uses that issue; and a request already covered by an open issue reuses it (add the request as a comment). Requests that change nothing in the repository (questions, investigations, running the app) need no issue; whatever they find follows the next rule.
- **One issue per finding**: Whenever you find something that needs fixing (a bug, a regression, a misconfiguration, a security or data risk, an outdated doc), create a GitHub issue for it, unless the current task already fixes it. This includes findings outside the task's scope and problems in third-party code that affect this app; out-of-scope findings are not fixed in the current branch.
- **Before creating**: search the open issues to avoid duplicates; if one exists, add the request or what you found as a comment instead.
- **Content**: write it in English. For a finding, say what is wrong, how it was observed or reproduced, and its impact; for a request, say what was asked and why, with any decisions agreed with the human. Always end with a "Done when" checklist and link related issues and PRs.
- **Tracking**: add the issue to an organization project with Status `Todo`, and list the issues you created in the PR description and in your report to the human:
    - **"MonAmie Docs" (#3)** for documentation issues: those whose fix changes only documentation (`docs/`, READMEs, `AGENTS.md`, rule files);
    - **"MonAmie App" (#2)** for everything else, including issues whose fix changes both code and its documentation.

## Communicating with the Human

Every output to the human must be didactic: the goal is that they understand what happened and why, not only that the task is done.
- **Start from what they know**: define each technical term the first time it appears and do not assume prior knowledge of CI, Firebase, IAM, isolates or the plugins' internals.
- **Explain the why**: say the cause behind a result or a decision, pointing to the file and line that show it.
- **One analogy at most**, and only when it helps; replace it with another if the human does not understand it.
- **Show, do not only tell**: when a flow or lifecycle is hard to follow, offer a diagram in a standard notation (e.g. UML) instead of an invented one.
- **Be honest about limits**: say what was not checked or could not be verified.

## Language Conventions

- Commit messages must be written in English (subject and body), regardless of the language used in the conversation.
- Code comments (including doc comments `///`) must be written in English, regardless of the language used in the conversation.
- Exception: documentation files inside `docs/pt-br/` must be written in Brazilian Portuguese (pt-BR).

## Security & Guardrails

- Never commit or log API keys, access tokens, or secrets.
- Never alter database schemas or run destructive migrations automatically.
- Do not edit generated folders directly (`/generated`, `/dist`, lockfiles etc).