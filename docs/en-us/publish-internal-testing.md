# Internal Testing Release

This guide takes an app from zero to the Google Play **internal testing** track and shows how each new
version is published after that. Almost everything is done once. **For each new version, the only manual
step is merging a PR into `main`**: the rest is automatic. How the automation works is explained in
[understanding-ci.md](understanding-ci.md).

## Overview

Steps are identified by group, according to how often they are done:

| Group | Frequency | Steps |
| :--- | :--- | :--- |
| **A** | Once for the company | A1 keystore · A2 to A4 CI foundation in Google Cloud |
| **B** | Once per machine or clone | B1 `key.properties` |
| **C** | Once per app (client) | C1 to C4 Firebase · C5 to C7 first release, manual · C8 Play SHAs · C9 to C12 app CI |
| **D** | On every new version | D1 merge the PR · D2 automatic release ⚙️ |

| On every new version | Before CI | With CI |
| :--- | :--- | :--- |
| Manual steps | 5: bump the versionCode, build the bundle, upload, fill in release notes and release | 1: merge the PR |

### Dependencies between steps

```mermaid
flowchart LR
    nS((" "))
    nK((" "))
    nW((" "))
    nF1((" "))
    nF2((" "))
    nB((" "))
    nU((" "))
    nP((" "))
    nSA((" "))
    nI((" "))
    nCI((" "))
    nM((" "))
    nE((" "))

    nS -->|A1| nK
    nS -->|A2| nCI
    nS -->|A3| nW
    nW -->|A4| nCI
    nK -->|B1| nB
    nK -->|C1| nF1
    nS -->|C2| nF1
    nF1 -->|C3| nF2
    nF2 -->|C4| nB
    nS -->|C5| nU
    nB -->|C6| nU
    nU -->|C7| nP
    nP -->|C8| nE
    nS -->|C9| nSA
    nSA -.-> nI
    nP -.-> nI
    nSA -->|C10| nCI
    nI -->|C11| nCI
    nK -->|C12| nCI
    nCI -->|D1| nM
    nM -->|D2 ⚙️| nE

    %% once for the company (purple)
    linkStyle 0,1,2,3 stroke:#7b2d8e,stroke-width:3px
    %% once per machine (orange)
    linkStyle 4 stroke:#e69f00,stroke-width:3px
    %% once per app (blue)
    linkStyle 5,6,7,8,9,10,11,12,13,16,17,18 stroke:#0072b2,stroke-width:3px
    %% dependency only, no work (gray)
    linkStyle 14,15 stroke:#999999,stroke-width:1px
    %% every version: manual (green) and automatic (dashed green)
    linkStyle 19 stroke:#009e73,stroke-width:3px
    linkStyle 20 stroke:#009e73,stroke-width:3px,stroke-dasharray:6 4
```

**How to read it:**
- **Edges** are steps, labeled with the step ID. **Nodes** are instants: the moment the following steps
  can start.
- A node is only reached when **all** edges arriving at it have finished.
- Edges leaving the same node can be done **in parallel**.
- A **thin dotted edge with no label** is a dependency only, with no work. For example, inviting the service
  account (C11) requires that it already exists (C9) and that the app is already on Play (C7).
- Colors:
  - 🟣 once for the company;
  - 🟠 once per machine;
  - 🔵 once per app;
  - 🟢 every version. The **dashed** edge (D2) is run automatically by CI. D1 and D2 repeat for every version.

## Values used

The commands in this guide use the variables below. Paste the block into your terminal before starting:

```bash
# Company
GCP_PROJECT=ci-cd-management      # Google Cloud project dedicated to CI
GCP_PROJECT_NUMBER=787253151660   # gcloud projects describe $GCP_PROJECT --format='value(projectNumber)'
POOL=github-actions               # workload identity pool (A3)
PROVIDER=github                   # GitHub provider (A4)
GITHUB_ORG_ID=336690459           # gh api orgs/monamienet --jq .id

# App
REPO=monamienet/monamie-app
SUBJECT_PREFIX=$(gh api repos/$REPO/actions/oidc/customization/sub --jq .sub_claim_prefix)  # start of the token subject (C10)
FIREBASE_PROJECT=monamienet-aquariustur
SA_NAME=wlif-monamie-app-play     # deploy service account (C9)
SA_EMAIL=$SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com
```

For another app (client):
- change the values of the *App* group;
- in the workflow [`.github/workflows/deploy-play-internal.yml`](../../.github/workflows/deploy-play-internal.yml),
  update `--flavor`, `releaseFiles`, `packageName` and `service_account`.

---

## A. Once for the company

### A1. Generate the upload keystore

The keystore signs the bundles uploaded to Play and is the same for all of the company's apps. **Keep a
backup off the machine:** without it, no app can receive new versions.

```bash
keytool -genkey -v \
  -keystore <PATH>/upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias <ALIAS> \
  -dname "CN=MonAmieNet, O=MonAmieNet, C=BR" \
  -storepass '<PASSWORD>' -keypass '<PASSWORD>'
```

### A2. Enable the Play API in the CI project

Without the API enabled, Google refuses the publishing calls made by CI.

```bash
gcloud services enable androidpublisher.googleapis.com --project=$GCP_PROJECT
```

### A3. Create the workload identity pool

The pool groups the external identities (here, GitHub workflows) that Google Cloud accepts. It serves
every pipeline of the organization.

```bash
gcloud iam workload-identity-pools create $POOL \
  --project=$GCP_PROJECT \
  --location=global \
  --display-name="GitHub Actions" \
  --description="GitHub Actions workflows of the monamienet organization"
```

### A4. Create the GitHub provider

The provider makes the pool trust GitHub Actions tokens, but only those from the `monamienet`
organization. The condition uses the numeric ID because, unlike the name, it is never reused.

```bash
gcloud iam workload-identity-pools providers create-oidc $PROVIDER \
  --project=$GCP_PROJECT \
  --location=global \
  --workload-identity-pool=$POOL \
  --display-name="GitHub" \
  --issuer-uri="https://token.actions.githubusercontent.com/" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id" \
  --attribute-condition="assertion.repository_owner_id=='$GITHUB_ORG_ID'"
```

**Check A2 to A4:**

```bash
gcloud services list --enabled --project=$GCP_PROJECT --filter="config.name=androidpublisher.googleapis.com"
gcloud iam workload-identity-pools providers describe $PROVIDER --workload-identity-pool=$POOL \
  --location=global --project=$GCP_PROJECT --format="yaml(state,attributeCondition)"
```

The expected result is the API listed, `state: ACTIVE` and the condition with the organization ID.

## B. Once per machine or clone

### B1. Create `android/key.properties`

This file tells Gradle where the keystore is. It is in `.gitignore`, so each machine needs its own. It is
only needed for **local** release builds, such as the first release (C6), because CI assembles its own
from the secrets (C12).

```properties
storePassword=<PASSWORD>
keyPassword=<PASSWORD>
keyAlias=<ALIAS>
storeFile=<PATH>/upload.jks
```

> **Fail-fast:** without this file, or with an empty property, every release build fails with the message
> `Release signing: ...`. There is no fallback to the debug key, whose bundle Play would reject. Debug
> builds (`flutter run --flavor aquariustur`) do not need the keystore.

## C. Once per app (client)

There are three tracks that can run in parallel: Firebase (C1 to C4), first release (C5 to C8) and app CI
(C9 to C12). The diagram shows what depends on what.

### C1. Get the upload key SHAs

```bash
keytool -list -v -keystore <PATH>/upload.jks -alias <ALIAS> | grep -E "SHA1|SHA256"
```

### C2. Get the Android app ID in Firebase

```bash
firebase apps:list ANDROID --project $FIREBASE_PROJECT
APP_ID=<value of the "App ID" column>
```

### C3. Register the SHAs in Firebase

Google sign-in only works for apps whose signature Firebase knows.

```bash
firebase apps:android:sha:create $APP_ID <SHA1> --project $FIREBASE_PROJECT
firebase apps:android:sha:create $APP_ID <SHA256> --project $FIREBASE_PROJECT
```

### C4. Update `google-services.json`

After updating it, commit the file, because it is versioned.

```bash
firebase apps:sdkconfig ANDROID $APP_ID --project $FIREBASE_PROJECT --out android/app/google-services.json
```

### C5. Create the tester list

In the Play Console, create a list of tester emails and associate it with the **internal testing** track.

### C6. Build the first bundle

Play only accepts uploads through the API after the app receives its first bundle through the Play
Console, so **the first version is manual**.

1. In `pubspec.yaml`, set `version: a.b.c+d`. `a.b.c` is the *versionName*, shown in the store, and `d`
   is the *versionCode*. Use a `d` **below 101**, because numbers from 101 up are used by CI.
2. Build the bundle:

    ```bash
    flutter build appbundle --release --flavor aquariustur
    ```

    The output is `build/app/outputs/bundle/aquariusturRelease/app-aquariustur-release.aab`.
    `--flavor` is required: each `partners/<id>/` folder becomes a flavor, and without it the build
    fails listing the valid ids.

### C7. Upload and release the first bundle

In the Play Console, open **internal testing**, create a release, upload the `.aab`, fill in the release
notes and click **Save → Release**.

### C8. Register the Google Play signing SHAs in Firebase

Play re-signs the app with a Google key (*Play App Signing*). Without that key's SHAs in Firebase, Google
sign-in fails on testers' devices. Copy the SHA1 and SHA256 from *Play Console → App integrity → App
signing* and register them:

```bash
firebase apps:android:sha:create $APP_ID <PLAY_SHA1> --project $FIREBASE_PROJECT
firebase apps:android:sha:create $APP_ID <PLAY_SHA256> --project $FIREBASE_PROJECT
```

### C9. Create the deploy service account

This is the identity that publishes to Play. Each pipeline has its own, and it gets no Google Cloud roles.
The reason is in [understanding-ci.md](understanding-ci.md#why-a-dedicated-service-account).

```bash
gcloud iam service-accounts create $SA_NAME \
  --project=$GCP_PROJECT \
  --display-name="monamie-app Play publisher" \
  --description="Publishes $REPO to the Play internal track from GitHub Actions via WIF. Docs: docs/pt-br/publicar-teste-interno.md"
```

### C10. Allow only the `play-internal` environment to impersonate the service account

The `--member` is the exact *subject* GitHub puts in the token of a job running in this repository's
`play-internal` environment. Any other job is refused. The subject has the form
`<prefix>:environment:play-internal`. This repository uses GitHub's **immutable** format, in which the
prefix includes the numeric IDs of the organization and repository (`repo:monamienet@336690459/monamie-app@1407450217`).
That is why the prefix is read from the API (`SUBJECT_PREFIX`) instead of written by hand: with the old
format, `repo:monamienet/monamie-app`, Google refuses the job.

```bash
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --project=$GCP_PROJECT \
  --role=roles/iam.workloadIdentityUser \
  --member="principal://iam.googleapis.com/projects/$GCP_PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL/subject/$SUBJECT_PREFIX:environment:play-internal"
```

**Check:** `gcloud iam service-accounts get-iam-policy $SA_EMAIL --project=$GCP_PROJECT` must list a
`roles/iam.workloadIdentityUser` binding with that `principal://...`. If only the `etag` appears, the
command was not applied.

### C11. Invite the service account in the Play Console

1. In the Play Console, open **Users and permissions → Invite new users**.
2. Enter the service account email (`echo $SA_EMAIL`).
3. Under **App permissions**, add the app and check **only** the permission to release to testing tracks.
4. Click **Invite user**.

The permission may take up to 48 hours to take effect.

### C12. Create the GitHub environment and secrets

The `play-internal` environment holds the signing secrets and can only be used by `main`. **This
restriction is mandatory:** the permission from C10 trusts the environment, and the restriction is what
stops other branches from publishing.

| Secret | Value |
| :--- | :--- |
| `ANDROID_KEYSTORE_B64` | the keystore encoded in base64 |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` from `key.properties` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` from `key.properties` |
| `ANDROID_KEY_ALIAS` | `keyAlias` from `key.properties` |

In the UI, use *Settings → Environments*. From the terminal, at the repository root, the values go straight
from `key.properties` to GitHub without showing on screen:

```bash
prop() { grep "^$1=" android/key.properties | cut -d= -f2- | tr -d '\r\n'; }

gh api -X PUT repos/$REPO/environments/play-internal \
  -F 'deployment_branch_policy[protected_branches]=false' \
  -F 'deployment_branch_policy[custom_branch_policies]=true'
gh api -X POST repos/$REPO/environments/play-internal/deployment-branch-policies -f name=main

prop storePassword | gh secret set ANDROID_KEYSTORE_PASSWORD --env play-internal --repo $REPO
prop keyPassword   | gh secret set ANDROID_KEY_PASSWORD      --env play-internal --repo $REPO
prop keyAlias      | gh secret set ANDROID_KEY_ALIAS         --env play-internal --repo $REPO
base64 -w0 "$(prop storeFile)" | gh secret set ANDROID_KEYSTORE_B64 --env play-internal --repo $REPO
```

**Check:** `gh secret list --env play-internal --repo $REPO` must list the 4 secrets, and
`gh api repos/$REPO/environments/play-internal/deployment-branch-policies --jq '.branch_policies[].name'`
must print `main`.

## D. On every new version

### D1. Merge the PR into `main`

This is the only manual step. To change the versionName (for example, from `1.0.0` to `1.1.0`), edit the
`version:` in `pubspec.yaml` in the PR itself. The versionCode is automatic.

### D2. Automatic release ⚙️

The merge triggers the workflow, which runs the tests, builds and signs the bundle, uploads it to Play and
releases the version to testers. Nothing needs to be done, but it is worth knowing:

- **Monitoring:** under *Actions → Deploy to Play (internal)*, each run shows the logs of every step. If
  anything fails, nothing is uploaded and whoever pushed gets an email.
- **Publishing again without a merge**, for example after fixing a permission: use *Run workflow* on `main`.
- **Release notes:** optional on the internal track, and the workflow does not fill them in. If you want
  notes, edit the release in the Play Console.
- ⚠️ **Do not rename the workflow file.** The run number, used as versionCode, is counted per file.
  Renaming it restarts the count at 1, and Play refuses duplicate versionCodes.

**Without CI:** if the workflow is unavailable, repeat C6 and C7 with a versionCode greater than the last
uploaded version's, which is shown in the Play Console.

---

## Common problems

| Message | Cause and fix |
| :--- | :--- |
| `Release signing: ...` | `key.properties` or the keystore is incomplete. Locally, check B1. On CI, check the C12 secrets. |
| `Secret ANDROID_... is empty` | The secret was not added to the `play-internal` environment, or it was added as a repository secret (C12). |
| `The given credential is rejected by the attribute condition` | The token did not come from the `monamienet` organization. Check the provider condition (A4). |
| `Permission 'iam.serviceAccounts.getAccessToken' denied` | The subject allowed in C10 is not the one GitHub sends. Check that the binding uses the prefix from the API (`echo $SUBJECT_PREFIX`) and that the job ran in the `play-internal` environment. |
| `The caller does not have permission` | The service account has no permission in the Play Console yet, or it has not propagated (C11). |
| `Version code ... has already been used` | The versionCode was already used. Usually the workflow file was renamed. Raise the `+ 100` in the workflow. |
| `Only releases with status draft may be created on draft app` | The app is still a draft on Play. Finish the first release (C7). |
| The app installs but Google sign-in fails | SHAs are missing in Firebase: from the upload key (C3) or from Google Play signing (C8). |
