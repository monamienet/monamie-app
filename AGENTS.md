# AGENTS.md

## Project Overview

This white-label application is maintained by the company MonAmieNet and provides clients services for tracking, coordination and comunication of teams.

## Business Archictecture

MonAmie has a single Google Developer Account, where every instance of this app is published.

Each instance of this app:
- belongs to one client $c$
- has its own and unique identity, which includes:
    - name (must be "MonAmie <instance_name>")
    - Application ID (Android) `android/app/build.gradle[.kts]`
    - Bundle Identifier (iOS) `ios/Runner.xcodeproj/project.pbxproj`
    - icons
    - theme
    - etc
- has its own separated Firebase Project which is associated to $c$'s billing account

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


## Running the Web App Locally

Follow `docs/en-us/run-web-locally.md`. Serve `build/web` on `http://localhost:5000`: it is the only local origin the OAuth web client accepts for Google sign-in. For unattended checks, capture the screenshot through CDP after Flutter paints, never with `--screenshot`.


## Git Workflow

- **Keep local `main` in sync**: Local `main` is a mirror of `origin/main` and must never receive direct commits. Before starting a task, fast-forward it: `git fetch origin main:main` from any other branch, or `git pull --ff-only` when `main` is checked out. If the fast-forward fails, local `main` has diverged; stop and report it instead of merging or resetting.
- **One branch per task**: Whenever a new task is assigned, create a new branch from the freshly synced `main` before making any changes (`git switch -c <type>/<short-description> main`). Never work directly on `main` or reuse a branch from a previous task.
- **Branch naming**: Prefix the branch with the change type, matching the commit convention (e.g. `feat/`, `fix/`, `chore/`, `docs/`, `build/`).
- **Pull request after human approval**: When the task is finished, wait for explicit human approval before opening a pull request to merge the branch into `main`. Do not open the PR, or merge it, without that approval.
- **GitHub interactions via MCP**: Interact with GitHub (pull requests, issues, reviews, projects, comments, etc.) preferably through the GitHub MCP server tools. Fall back to the `gh` CLI only when the GitHub MCP server is unavailable in the session or does not support the required operation.

## Tracking Findings

- **One issue per finding**: Whenever you find something that needs fixing (a bug, a regression, a misconfiguration, a security or data risk, an outdated doc), create a GitHub issue for it, unless the current task already fixes it. This includes findings outside the task's scope and problems in third-party code that affect this app; out-of-scope findings are not fixed in the current branch.
- **Before creating**: search the open issues to avoid duplicates; if one exists, add what you found as a comment instead.
- **Content**: write it in English. Say what is wrong, how it was observed or reproduced, its impact, and a "Done when" checklist; link related issues and PRs.
- **Tracking**: add the issue to an organization project with Status `Todo`, and list the issues you created in the PR description and in your report to the human:
    - **"MonAmie Docs" (#3)** for documentation issues: those whose fix changes only documentation (`docs/`, READMEs, `AGENTS.md`, rule files);
    - **"MonAmie App" (#2)** for everything else, including issues whose fix changes both code and its documentation.

## Language Conventions

- Commit messages must be written in English (subject and body), regardless of the language used in the conversation.
- Code comments (including doc comments `///`) must be written in English, regardless of the language used in the conversation.
- Exception: documentation files inside `docs/pt-br/` must be written in Brazilian Portuguese (pt-BR).

## Security & Guardrails

- Never commit or log API keys, access tokens, or secrets.
- Never alter database schemas or run destructive migrations automatically.
- Do not edit generated folders directly (`/generated`, `/dist`, lockfiles etc).