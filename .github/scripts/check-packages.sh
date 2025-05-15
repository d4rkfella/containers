#!/usr/bin/ash
set -e

apk add yq curl coreutils

echo "https://packages.darkfellanetwork.com/wolfi-os" >> /etc/apk/repositories
curl -sL https://packages.darkfellanetwork.com/wolfi-os/melange.rsa.pub -o /etc/apk/keys/melange.rsa.pub

apk update

APKO_FILE="${{ matrix.name }}/apko.yaml"
APP_NAME="${{ matrix.name }}"

echo "file_modified=false" >> "$GITHUB_OUTPUT"
echo "latest_version=" >> "$GITHUB_OUTPUT"

TMP_UPDATES=$(mktemp)
TMP_VERSIONS=$(mktemp)
TMP_COUNT=$(mktemp)
echo "0" > "$TMP_COUNT"
TMP_MATCHED=$(mktemp)
echo "0" > "$TMP_MATCHED"

PINNED_PACKAGES=$(yq e ".contents.packages[] | select(test(\"=\"))" "$APKO_FILE" || echo "")
if [ -z "$PINNED_PACKAGES" ]; then
  echo "ℹ️ No pinned packages found in $APKO_FILE"
  exit 0
fi

echo "$PINNED_PACKAGES" | while read -r PACKAGE_PIN_LINE; do
  PACKAGE_NAME=$(echo "$PACKAGE_PIN_LINE" | cut -d= -f1)
  CURRENT_VERSION=$(echo "$PACKAGE_PIN_LINE" | cut -d= -f2)

  case "$PACKAGE_NAME" in
    *"$APP_NAME"*)
      MATCHED=$(cat "$TMP_MATCHED")
      echo $((MATCHED + 1)) > "$TMP_MATCHED"

      LATEST_FULL_STRING=$(apk search --exact "$PACKAGE_NAME" | grep -v "^fetch" | head -n 1 || true)
      LATEST_VERSION=$(echo "$LATEST_FULL_STRING" | sed "s/^${PACKAGE_NAME}-//" || true)

      if [ -z "$LATEST_VERSION" ]; then
        echo "⚠️  Version check failed for $PACKAGE_NAME"
        continue
      fi

      echo "$LATEST_VERSION" >> "$TMP_VERSIONS"

      VERSION_COMPARE=$(apk version -t "$CURRENT_VERSION" "$LATEST_VERSION")
      case "$VERSION_COMPARE" in
        ">")
          echo "⚠️  Current version ($CURRENT_VERSION) is NEWER than available ($LATEST_VERSION) for $PACKAGE_NAME"
          ;;
        "=")
          echo "✓ $PACKAGE_NAME is up-to-date ($CURRENT_VERSION)"
          ;;
        "<")
          echo "🔄 Updating $PACKAGE_NAME: $CURRENT_VERSION → $LATEST_VERSION"
          yq e "(.contents.packages[] | select(. == \"$PACKAGE_NAME=$CURRENT_VERSION\")) = \"$PACKAGE_NAME=$LATEST_VERSION\"" -i "$APKO_FILE"
          echo "${PACKAGE_NAME}=${LATEST_VERSION}" >> "$TMP_UPDATES"
          echo "file_modified=true" >> "$GITHUB_OUTPUT"
          # Increment update count
          COUNT=$(cat "$TMP_COUNT")
          echo $((COUNT + 1)) > "$TMP_COUNT"
          ;;
        *)
          echo "⚠️  Invalid version comparison for $PACKAGE_NAME ($CURRENT_VERSION vs $LATEST_VERSION)"
          ;;
      esac
      ;;
  esac
done

UPDATED_COUNT=$(cat "$TMP_COUNT")
MATCHED_COUNT=$(cat "$TMP_MATCHED")

if [ -s "$TMP_VERSIONS" ]; then
  LATEST_VERSION=$(sort -Vr "$TMP_VERSIONS" | head -n1)
  echo "latest_version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
fi

if [ "$UPDATED_COUNT" -gt 0 ]; then
  echo "✅ Updated $UPDATED_COUNT/$MATCHED_COUNT packages:"
  cat "$TMP_UPDATES"
  echo "updated_packages<<EOF" >> "$GITHUB_OUTPUT"
  cat "$TMP_UPDATES" >> "$GITHUB_OUTPUT"
  echo "EOF" >> "$GITHUB_OUTPUT"
elif [ "$MATCHED_COUNT" -gt 0 ]; then
  echo "✅ All packages are up-to-date"
else
  echo "ℹ️ No packages matching '$APP_NAME' found"
fi

rm -f "$TMP_UPDATES" "$TMP_VERSIONS" "$TMP_COUNT" "$TMP_MATCHED"
