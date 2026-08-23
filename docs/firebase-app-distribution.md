# GitHub to Firebase App Distribution

The `firebase-app-distribution.yml` workflow builds a debug APK from the `dev` branch and uploads it to Firebase App Distribution automatically whenever Android, Flutter, or dependency files change. It intentionally skips distribution until the required secrets are present, avoiding failed releases or credentials in source control.

## One-time Firebase setup

Create or select the Firebase project that owns the Android app. Register the Android app with the exact current package name, `com.ialna.app`; Firebase package names are case-sensitive and cannot be changed after registration. In Firebase Console, open **Project settings → General** and copy the Android **App ID**. Then open **Project settings → Service accounts**, generate a new private key for a service account authorized to distribute builds, and keep the JSON file private.

In the GitHub repository, add these **Actions secrets** under **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `FIREBASE_APP_ID` | The Firebase Android App ID, such as `1:1234567890:android:abc123`. |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | The complete service-account JSON credential as a single secret value. |
| `FIREBASE_TESTER_GROUPS` | Optional Firebase App Distribution tester-group alias, such as `trusted-testers`. |

Create a tester group in Firebase App Distribution before the first automated upload if you want testers to be invited automatically. The workflow still uploads a release when this value is absent. It uses Application Default Credentials through `GOOGLE_APPLICATION_CREDENTIALS`; do not commit the JSON credential, `.firebaserc`, or `google-services.json` unless the app itself begins using Firebase SDKs.

## Website release synchronization

Before the optional Firebase upload, the workflow publishes the generated APK as a GitHub **public debug pre-release**. It then rewrites `website/src/release.generated.ts` with that release asset's direct URL, commits the generated metadata to `dev`, and manually triggers GitHub Pages. The website download button and QR code therefore follow the latest public debug build automatically. The workflow ignores `website/**` changes, preventing a release-update loop.

The direct APK is intentionally labelled as a debug-signed evaluation build, not a Play Store release. It is publicly downloadable without Firebase authentication, and Android may require users to allow installation from their browser or file manager. Firebase App Distribution remains an optional secondary internal-testing channel. Never publish Firebase's `binary_download_uri`: it is a signed URL that expires after one hour.

## First controlled run

Use **Actions → Firebase App Distribution → Run workflow** after adding the secrets. Check the logged Firebase Console URI and tester URI. Firebase sends invited testers an email and the CLI prints a tester link for the release. A subsequent eligible push to `dev` performs the same build and distribution automatically.

## Security and release boundary

This workflow distributes an unsigned debug APK for internal testing only. Do not use it as a Play Store release pipeline. Scope the service account to the minimum project permissions required for App Distribution, rotate the key if exposed, and restrict repository write access because a push to `dev` causes an upload after secret configuration.
