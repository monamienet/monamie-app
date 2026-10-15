# Internal Testing Release

### In the Flutter project

1. Generate a keystore with the command 

    ```
    keytool -genkey -v \
      -keystore <OUTPUT_PATH> \
      -keyalg RSA -keysize 2048 -validity 10000 \
      -alias <ALIAS> \
      -dname "CN=MonAmieNet, O=MonAmieNet, C=BR" \
      -storepass '<PASSWORD>' -keypass '<PASSWORD>'
    ```

    > [!IMPORTANT]
    > Back up the keystore generated in the previous step!

1. Inside the Dart/Flutter project, create the file `android/key.properties` with the following content:

    ```
    storePassword=<PASSWORD>
    keyPassword=<PASSWORD>
    keyAlias=<ALIAS>
    storeFile=<OUTPUT_PATH>
    ```

    > [!IMPORTANT]
    > Add `key.properties` and `.jks` files to `.gitignore`.

1. Look up the SHA1 and SHA256 keys with the command `keytool -list -v -keystore <keystore_path> -alias <ALIAS> | grep -E "SHA1|SHA256"`

1. Look up the `<APP_ID>` using `firebase apps:list ANDROID --project PROJECT_ID`

1. Register the SHA1 key on the Android app in the Firebase project with `firebase apps:android:sha:create <APP_ID> <SHA1> --project <PROJECT_ID>`

1. Register the SHA256 key on the Android app in the Firebase project with `firebase apps:android:sha:create <APP_ID> <SHA256> --project <PROJECT_ID>`

1. Update `google-services.json` using `firebase apps:sdkconfig ANDROID <APP_ID> --project <PROJECT_ID> --out android/app/google-services.json`

1. Update the version in `pubspec.yaml`, keeping in mind that:
    - the version has the form `a.b.c+d`, where `a.b.c` is the ***versionName*** and d is the ***versionCode***
    - changing the ***versionName*** is optional
    - increasing the ***versionCode*** strictly is mandatory

1. Build the bundle with `flutter build appbundle --release`

### In the Google Play Console:

10. Create a tester list and associate it with the internal testing track

1. Upload the bundle generated in the previous step

1. Fill in the release notes

1. Save → Release

1. Copy the SHA1 and SHA256 keys that Google signs the app with, under *Play Console > App integrity > App signing*

1. Register the SHA1 key (signed by Google) on the Android app in the Firebase project with `firebase apps:android:sha:create <APP_ID> <SHA1> --project <PROJECT_ID>`

1. Register the SHA256 key (signed by Google) on the Android app in the Firebase project with `firebase apps:android:sha:create <APP_ID> <SHA256> --project <PROJECT_ID>`


### How often each step runs

Numbering follows the steps above (1 to 9 in the Flutter project, 10 to 16 in the Google Play Console).

| Frequency | Steps | Notes |
| :--- | :--- | :--- |
| Once for the company | 1 | The keystore is the same for all apps and tracks. Back it up right after generating it. |
| Once per machine or repository clone | 2 | `key.properties` is not versioned, so each environment needs its own. |
| Once per app (client) | 3, 4, 5, 6, 7, 10, 14, 15, 16 | Steps 14 to 16 can only be done after the first upload to the Play Console. |
| On every new version | 8, 9, 11, 12, 13 | Step 8 requires a `versionCode` greater than that of any bundle already uploaded. |

### Temporal dependency between steps

Step numbering is the same as in this guide.

#### How to read

- **Edges** are the steps (label = step number, as in the list above). **Nodes** are instants: the start of steps that depend on what has finished.
- A node is only reached when **all** the edges that arrive at it have finished.
- Edges leaving the same node can be done **in parallel**.

```mermaid
flowchart LR
    A((" "))
    B((" "))
    H((" "))
    I((" "))
    K((" "))
    L((" "))
    M((" "))
    O((" "))
    P((" "))
    Q((" "))
    R((" "))

    A -->|1| B
    A -->|4| H
    A -->|8| K
    A -->|10| O

    B -->|2| K
    B -->|3| H

    H -->|5| I
    H -->|6| I

    I -->|7| K

    K -->|9| L
    L -->|11| M
    M -->|12| O

    O -->|13| P
    P -->|14| Q
    Q -->|15| R
    Q -->|16| R

    %% once for the company (purple)
    linkStyle 0 stroke:#7b2d8e,stroke-width:3px
    %% once per machine (orange)
    linkStyle 4 stroke:#e69f00,stroke-width:3px
    %% once per app (blue)
    linkStyle 1,3,5,6,7,8,13,14,15 stroke:#0072b2,stroke-width:3px
    %% every version (green)
    linkStyle 2,9,10,11,12 stroke:#009e73,stroke-width:3px
```

Edge colors, according to the frequency table:

- 🟣 Once for the company (step 1)
- 🟠 Once per machine or repository clone (step 2)
- 🔵 Once per app (steps 3, 4, 5, 6, 7, 10, 14, 15 and 16)
- 🟢 On every new version (steps 8, 9, 11, 12 and 13)
