# AGENTS.md

## Project Overview

This application is maintained by the company MonAmieNet and provides clients (organizations) services for tracking, coordination and comunication of teams.

## Business Architecture

MonAmie publishes a **single app** on its Google Developer Account: `org.monamienet.app`, named "MonAmie" (launcher, Play listing and native splash are the same for everyone). Each organization (client) is on one of two **plans** (`plan` in the central registry `organizations/{id}`):
- **Standard**: its own Firebase project `monamienet-<id>`, on the organization's own billing account;
- **Community** (free): the shared project `monamienet-community`, owned and paid by MonAmieNet, restricted to the *Economia* tracking preset (one position every 15 minutes at most, enforced by the rules through `organizations/{id}/config/plan.minIntervalMinutes`). The central project and the Community project stay separate projects (Auth, IAM and quotas are per project).

On both plans **every organization's data lives under `organizations/{organizationId}/…`** of its project: `config/branding` (publicly readable), `config/plan`, `config/tracking` (the administrators' period and radius, followed live by the background service; the map's one freshness threshold, the validity, is fixed at 12 minutes, see `docs/pt-br/compartilhamento.md`), `organizationMemberships/{personKey}` and `groups/{groupId}` with `groupMemberships/{personKey}` (who belongs, see below), and `groups/{groupId}/positions/{personKey}` (a person's last position in that group: `email`, `name`, `lat`, `lng`, `capturedAt` on the device clock, `receivedAt` on the server clock, `isPublishing`, `removedAt`, null while they publish there) with `trail/{pointId}` and `trailDays/{yyyy-mm-dd}` (a per-day summary, `lastAt` and `pointCount`, written in the same batch as each position, so the history calendar reads at most one document per person and day). A Standard project is simply a project holding one organization, so code, rules and tests are the same for both plans; no path is ever read at the root. The rules scope every match by organization (the caller's membership documents) and test cross-organization access. Collection and field names live in one place per codebase: `FirestorePaths` (`lib/app/data/firebase/firestore_paths.dart`, also used by `tool/`) and `firestore_paths.js` in `functions/` and `central/functions/`; use them instead of string literals.

The app binds the organization **at runtime**, after Google sign-in, never at build time:
1. Google sign-in goes through the central MonAmie project `monamienet-app` (the `[DEFAULT]` Firebase app). Only one OAuth client may exist per package + SHA-1, so it lives there, and every organization project allows the central web client under "Allowed client IDs".
2. The central `resolveOrganizations` function (`central/functions/`) reads the user's organizations from `accounts/{personKey}` in the central project (an index the central functions keep next to the memberships, see below), keeping those whose entry in the central registry `organizations/{id}` has a `status` the app shows. The status follows a fixed lifecycle (`reserved` → `awaiting_billing`/`provisioning` → `active`, plus `failed`, `migrating` and `deleting`) written only by the central functions; its timed exits delete the organization's project and registry entry and retire the id forever in `retiredOrganizationIds/{id}` (see `docs/en-us/white-label.md`, *Organization status*). Organizations are created in the app (`createOrganization`; the creator becomes the owner and first administrator) and an account is deleted in the app with 30 days to cancel (`accountDeletions/{personKey}`; an owner's organization goes to `deleting` with it); see the guide's sections 11 and 12.
3. The app binds the chosen organization (`OrganizationSession`): its Firebase project (a named app `organization-<id>`) and its branding, together, and remembers the binding on the device (`SharedPreferences`) until sign-out or removal from the organization (its `organizationMemberships/{personKey}` disappears).

Where each value lives:
- **Organization's choice**: name (required) and a catalog `themeId` in `organizations/<id>/config/branding`, plus an optional logo, one square 512 px PNG at `organizations/<id>/logo.png` in the organization's Cloud Storage (converted on an administrator's device from any format; never an SVG). Administrators change them in the app (*Aparência*, through the `setBranding` function, which validates the theme against the central catalog); `dart run tool/organization.dart publish <id> --name … --theme …` sets name and theme for organizations onboarded by hand.
- **MonAmie's choice**: the organization's `status` in `organizations/{id}` and the **theme catalog** `themes/{id}` (`name`, `primary`, `dark`, `light`, `onPrimary`, `onDark`, `order`, `active`), both in the central project. Organizations pick a theme, never free colors; an unknown or missing `themeId` falls back to Grafite, and a retired theme (`active: false`) still resolves. The catalog is seeded with `dart run tool/organization.dart themes` and is publicly readable.
- **Derived by rule**, never stored: project `monamienet-<id>` (Standard) or `monamienet-community` (Community, from `plan`), and `personKey(email)`, the key of a person's documents.
- **Names never side by side**: "MonAmie" appears alone on MonAmie's own screens (launcher, Play listing, splash, sign-in, organization picker, organization creation); once an organization is bound, the app shows only the organization's name. `publish` refuses an organization name starting with "MonAmie ".
- **Owned by another system**, fetched, never versioned: the central `google-services.json` (build time, `tool/organization.dart firebase`) and each organization's Firebase options (runtime, `resolveOrganizations`).

Rules that come from the plugins' source code: never `delete()` an organization `FirebaseApp` (cloud_firestore caches instances per app name forever); the organization app is created natively in `MonAmieApplication.kt` so the UI and the tracking service engines never race to create it; the binding lives in `SharedPreferences`, not Hive, because two isolates read it.

Onboarding an organization needs no app release: see `docs/en-us/white-label.md`. CI only ships the app: Cloud Functions and rules are deployed by hand, `central/` once to `monamienet-app` and `functions/` + `firestore.rules` + `firestore.indexes.json` + `storage.rules` to every organization project.

### Organizations, Groups and Users

> **Migration in progress (#159).** Groups and roles are moving from Google Groups to Firestore membership documents. The approved plan, with one issue per phase, is [docs/pt-br/migracao-grupos-firestore.md](docs/pt-br/migracao-grupos-firestore.md). Server and app are done (#163): no code reads Google Groups, the groups gateway or custom claims any more; the old test data is recreated and Google Groups are switched off by hand in phase 5 (#164). Read the plan before touching groups, roles, invites, positions or Firestore paths.

Who belongs where lives in Firestore documents of the organization's project, **written only by the central functions** (`central/functions/`, Admin SDK) and by `dart run tool/organization.dart add-admin`; the rules let no client write them.

- **personKey**: every document about a person is keyed by `personKey(email)`, the lowercase-hex SHA-256 of the trimmed, lowercased e-mail, so no e-mail appears in a document name; each document also stores `email`. Twins that must agree: `person_key.js` in `central/functions/` and `functions/`, `lib/app/data/organization/person_key.dart` (also used by `tool/`), and `personKey()` in `firestore.rules` and `storage.rules`. Fixed test vector: `ana@example.com` → `8e43ca37…a018e11`.
- **Organization membership** `organizations/{id}/organizationMemberships/{personKey}`: `{email, role: 'admin' | 'member', addedAt}`. Having one is being in the organization; it disappearing is being removed.
- **Groups** `organizations/{id}/groups/{groupId}` (`{name, createdAt}`, Firestore auto ids, never reused) and **group memberships** `groups/{groupId}/groupMemberships/{personKey}`: `{email, organizationId, roles, addedAt}`, roles sorted and non-empty among `publisher` (publishes their own position in that group), `subscriber` (sees the group's map, trail and calendar) and `maintainer` (reserved for #165, grants nothing extra yet). A person finds their groups with a collection-group query on `groupMemberships` by `email` and `organizationId` (indexes in `firestore.indexes.json`).
- **Administrators** (*administradores*) are the people whose organization membership has `role: 'admin'`, and **only** they: administration powers (groups, invites, appearance, tracking settings, seeing every group) come from `organizations/{id}/organizationMemberships`, written only by the central functions. The rules, `storage.rules` (the logo), `setBranding` and the central functions all read that same document.
- **The owner** (*titular* in the app, a gender-neutral word) is the person who created the organization, recorded as `ownerEmail` in the central registry `organizations/{id}`. The owner is always an administrator: creation writes their `admin` membership, and no function demotes or removes them. Deleting their account deletes the organization (confirmed by typing its id), and `resolveOrganizations` tells the app so (`owner`). A non-owner who deletes their account leaves every group and the organization.
- **`accounts/{personKey}`** in the central project, `{email, organizationIds}`: an index of a person's organizations for `resolveOrganizations`, written by the central functions *after* the organization project ("the organization wins": an extra id is dropped by the app when it finds no membership; a missing one is reported by `dart run tool/organization.dart check`). No client reads it. Retiring an organization removes its id from every entry.
- **Changing roles** = `setMemberRoles`; losing `publisher` (or leaving the group with `removeMember`) marks the person's position in that group with `removedAt`, so the map leaves it out and the history keeps it. Leaving one's last group also leaves the organization, unless one is an administrator. Joining happens only through an invite (`acceptInvite`: organization membership `member` if absent plus the group membership, one batch).
- **In the app**: what a person may do (`Capabilities`) comes from listening to their own organization membership and, with the collection-group query, to their group memberships (`GroupMapController`, behind the `GroupMapState` contract), so a change made by an administrator shows at once and a missing organization membership makes the app forget the organization. The map of a group listens to `groups/{groupId}/positions` with `removedAt == null`; the history reads every position of the group (removed people included), its `trail` and its `trailDays`. There is no "active group": while sharing is on, the background service (its own isolate, its own listener on the person's memberships) publishes each position in **every** group where the person is `publisher`, one batch per group (position, trail point, day summary), and a group that refuses does not stop the others. The administrators' screens call the central group and invite functions with `groupId`.
- **Who runs it**: the membership-writing calls run as `groups-admin@monamienet-app.iam.gserviceaccount.com` (it keeps its old name; it needs `roles/datastore.user` on the central project, on the Community project and on each Standard project); the scheduled expiry and erase run as `partner-expirer@`.

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