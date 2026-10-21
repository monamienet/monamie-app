# One app, many partners

MonAmie publishes one app, `org.monamienet.app` ("MonAmie"). Each partner (a client organization) keeps its own Firebase project, its own data and its own bill. The app learns which partner a user belongs to **after** the user signs in, and only then shows the partner's name, colors and logo.

This guide explains how that works, what MonAmie sets up once, and how to onboard a partner without releasing the app. The decisions behind it are in issue #28.

## 1. Partner vs. user

| | Partner | User |
|---|---|---|
| What | a client organization | a person |
| Example | AquariusTur | Maria |
| Owns | branding, Firebase project `monamienet-<id>`, root group `<id>00@monamienet.org` | a Google account |
| Signs in? | no | yes |

A Google account says nothing about a partner. The bridge is the **groups**: every partner has one root group `<id>00@monamienet.org` and subgroups `<id>01` … `<id>99`. Adding a person's e-mail to one of them is what makes them a user of that partner. Because the suffix is always two digits, the partner id is the group name without its last two characters: `aquariustur01@monamienet.org` → `aquariustur`.

## 2. What happens when a user signs in

1. **Google sign-in** to the central project `monamienet-app`. The screen is MonAmie-branded: no partner is known yet.
2. **`resolvePartners`** (central function) asks the groups gateway for the user's groups, turns the names into partner ids, keeps the ones marked active in the central registry `partners/{id}`, and returns each partner's Firebase options.
3. The app reads each partner's **`config/branding`** (public). With no partner the user sees "your account is not linked to any organization"; with one, the app enters it; with several, a picker shows each partner's name and icon.
4. **Binding:** the partner's Firebase project (a named Firebase app `partner-<id>`), its root group and its branding are bound together. The app signs in to the partner project with the same Google ID token (the partner allows the central web client) and runs the partner's `syncClaims`, which decides what the user may see, exactly as before.
5. **Remembering:** the binding is saved on the device. Next launches open directly in the partner's brand, without the central project.

The app **forgets** the partner on sign-out, when a group refresh finds no group of the partner anymore, or when `syncClaims` returns no roles.

The launcher icon, the app name on the home screen, the Play listing and the native splash are always MonAmie: Android reads them from the installed package.

## 3. Where each value lives

| Kind | Examples | Where |
|---|---|---|
| Partner's choice | name (required); colors, logo, icon (optional) | `config/branding` in `monamienet-<id>` |
| MonAmie's choice | partner is active | `partners/{id}` in `monamienet-app` |
| Derived by rule | `monamienet-<id>`, `<id>00@monamienet.org`, id from a group name | code |
| Fetched at build time | central `google-services.json` | `android/app/google-services.json` (gitignored) |
| Fetched at runtime | partner's Firebase options | `resolvePartners`, then the device |

Missing optional branding falls back on its own: no primary color → MonAmie blue `#315399`; no background → white; no logo → the name written in the partner's color; no icon → the name's initial in a circle.

## 4. One-time setup of the central project (maintainer)

1. Create the Firebase project **`monamienet-app`** on MonAmie's billing account (Blaze, for Functions). The id `app` is reserved: no partner can use it.
2. Authentication → enable **Google**. Fill in the OAuth consent screen as "MonAmie".
3. Register the **Android app** `org.monamienet.app` with the SHA-1 of the upload key, of Play App Signing and of each developer's debug key. Register one **web app**, and add `http://localhost:5000` and the hosting domain as authorized JavaScript origins of the web OAuth client.
4. Enable Firestore and deploy the central project:
   ```sh
   cd central/functions && npm ci && cd ..
   firebase deploy --project monamienet-app --only functions,firestore
   ```
5. Grant the function's runtime service account (`<project number>-compute@developer.gserviceaccount.com`) the custom role **`firebaseAppConfigReader`** (`firebase.clients.list`, `firebase.clients.get`) **on each partner project only** (onboarding step 7). It reads partners' Firebase options and nothing else.
6. CI: bind `firebaseAppConfigReader` for the config service account `wlif-monamie-app-config@ci-cd-management.iam.gserviceaccount.com` on `monamienet-app`, and remove its binding from `monamienet-aquariustur` (the build only reads the central config now).
7. Play Console: create the app `org.monamienet.app`, upload the first bundle manually, fill in Data safety and the **background location** declaration (reviewed by Google), and give the publisher service account access to it. Then unpublish `org.monamienet.aquariustur`.
8. Check that the groups gateway accepts Firebase ID tokens from `monamienet-app` (see issue #72).

## 5. Onboarding a partner (no app release)

Steps 1–9 cover the three required things: project, root group and name. Step 10 is the gate.

**Partner's Firebase project**
1. Create `monamienet-<id>` on the partner's billing account.
2. Enable Firestore and the Google sign-in provider; under **Allowed client IDs**, add the central web client id.
3. Register the Android app `org.monamienet.app` **without a SHA-1** (the package + SHA-1 pair can only have an OAuth client in one project: the central one) and one web app. Add the hosting domain to the authorized domains.
4. Restrict the API keys: Android to the package + SHA-1, browser to the domains.
5. Deploy the rules and `syncClaims` (from the repository root):
   ```sh
   firebase deploy --project monamienet-<id> --only firestore:rules,functions
   ```

**Groups and access**

6. Create the root group `<id>00@monamienet.org` and the subgroups `<id>01`, `<id>02`… with the users.
7. Grant `firebaseAppConfigReader` to the central function's service account on **this project only**.
8. If the groups gateway keeps a list of accepted projects, add `monamienet-<id>`.

**Branding and activation**

9. Publish the branding from the onboarding form (download the submission with `rclone` into a temp folder, see `AGENTS.md`):
   ```sh
   dart run tool/partner.dart publish <id> --name "<Name>" \
     --primary '#RRGGBB' --secondary '#RRGGBB' \
     --logo <dir>/logo-com-texto.svg --icon <dir>/logo-sem-texto.svg
   ```
   Only `--name` is required; add `--dry-run` to check first. Publishing again later updates the brand for every user on their next launch.
10. Check and activate (activation runs the same checks and refuses on failure):
    ```sh
    dart run tool/partner.dart check <id>
    dart run tool/partner.dart activate <id>
    ```
    `activate <id> --deactivate` stops new sign-ins to a partner.

The tool uses your `firebase login` and `gcloud auth login` accounts.

## 6. Building

- **Android:** `flutter build apk` (no `--flavor`). The build fetches the central `google-services.json` when it is missing; `REFRESH_FIREBASE_CONFIG=1` refreshes it.
- **Web:** `dart run tool/partner.dart web` writes `web/central/firebase.json` (central Firebase options and the Google client id), then `flutter build web`. See `run-web-locally.md`.
