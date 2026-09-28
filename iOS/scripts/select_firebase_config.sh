#!/bin/sh
set -eu

case "${PRODUCT_BUNDLE_IDENTIFIER:-}" in
  io.agora.convoai) firebase_variant=prod ;;
  agora.convoai.test) firebase_variant=test ;;
  *)
    printf 'error: No Firebase configuration for bundle ID %s\n' "${PRODUCT_BUNDLE_IDENTIFIER:-<unset>}" >&2
    exit 1
    ;;
esac

source_plist="${SRCROOT:?}/firebase/${firebase_variant}/GoogleService-Info.plist"
target_plist="${TARGET_BUILD_DIR:?}/${UNLOCALIZED_RESOURCES_FOLDER_PATH:?}/GoogleService-Info.plist"

if [ ! -f "$source_plist" ]; then
  printf 'error: Missing Firebase configuration: %s\n' "$source_plist" >&2
  exit 1
fi

configured_bundle_id=$(/usr/bin/plutil -extract BUNDLE_ID raw "$source_plist")
if [ "$configured_bundle_id" != "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
  printf 'error: Firebase configuration does not match bundle ID %s\n' "$PRODUCT_BUNDLE_IDENTIFIER" >&2
  exit 1
fi

mkdir -p "$(dirname "$target_plist")"
cp "$source_plist" "$target_plist"
