#!/usr/bin/env bash
# Desert Signal release helper: create one persistent evaluation key so public
# APK updates keep the same Android signature. Never commit the keystore or its
# passwords; store them in a password manager and GitHub Actions secrets.
set -euo pipefail

out_dir="${1:-$HOME/.3ialna-signing}"
mkdir -p "$out_dir"
chmod 700 "$out_dir"
keystore="$out_dir/3ialna-evaluation.keystore"

if [[ -e "$keystore" ]]; then
  echo "Refusing to overwrite existing keystore: $keystore" >&2
  exit 1
fi

read -r -s -p "Keystore password: " store_password
printf '\n'
read -r -s -p "Confirm keystore password: " store_password_confirm
printf '\n'
[[ "$store_password" == "$store_password_confirm" && -n "$store_password" ]] || { echo "Passwords do not match or are empty." >&2; exit 1; }

read -r -p "Key alias [3ialna-evaluation]: " key_alias
key_alias="${key_alias:-3ialna-evaluation}"
read -r -s -p "Key password (blank uses keystore password): " key_password
printf '\n'
key_password="${key_password:-$store_password}"

keytool -genkeypair -v \
  -keystore "$keystore" \
  -storetype JKS \
  -storepass "$store_password" \
  -keypass "$key_password" \
  -alias "$key_alias" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=3ialna Evaluation, OU=Android, O=3ialna, L=Remote, ST=NA, C=US"
chmod 600 "$keystore"

printf '\nCreated: %s\n' "$keystore"
printf '%s\n' 'Create these GitHub Actions secrets without committing the keystore:'
printf '%s\n' 'ANDROID_EVALUATION_KEYSTORE_BASE64 = base64 -w 0 < the-keystore-file'
printf 'ANDROID_EVALUATION_KEYSTORE_PASSWORD = <your-keystore-password>\n'
printf 'ANDROID_EVALUATION_KEY_ALIAS = %s\n' "$key_alias"
printf 'ANDROID_EVALUATION_KEY_PASSWORD = <your-key-password>\n'
printf '\n%s\n' 'Keep this keystore and both passwords backed up. Losing the key prevents in-place APK upgrades.'
