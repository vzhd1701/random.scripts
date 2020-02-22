#!/bin/bash

set -e

get_addon_version() {
  sed -n 's/.*<addon[^>]\+version="\(.\+\)".*/\1/p' "$1"
}

generate_file_md5() {
  md5sum "$1" | cut -c 1-32 > "$1.md5"
}

# Globals
# $REPO_SIGN_KEY_ID
# $REPO_GH_TOKEN
# $KODI_ADDON

USER_NAME="vzhd1701"
USER_EMAIL="vzhd1701@gmail.com"

KODI_ADDON_XML_PATH=$(realpath "$KODI_ADDON/addon.xml")
KODI_ADDON_VERSION=$(get_addon_version "$KODI_ADDON_XML_PATH")
KODI_ADDON_ZIP="$KODI_ADDON-$KODI_ADDON_VERSION.zip"
KODI_ADDON_ZIP_PATH=$(realpath "$KODI_ADDON_ZIP")

KODI_ADDON_REPO="kodi.repository"
KODI_ADDON_REPO_URL="https://${REPO_GH_TOKEN}@github.com/${USER_NAME}/${KODI_ADDON_REPO}.git"

case $1 in
  -z|--zip)
    if [[ -f "$KODI_ADDON_ZIP" ]]; then
      echo "Addon ZIP already exists."
      exit 0
    fi

    echo "Cleaning up Python bytecode after testing..."
    find . -regex ".*\.\(py[cod]\)$" -type f -delete

    echo "Packing addon ZIP file..."
    zip -q -r "$KODI_ADDON_ZIP" "$KODI_ADDON"

    exit 0
    ;;
  -r|--repository)
    echo "Cloning my Kodi addon repository..."
    git clone "$KODI_ADDON_REPO_URL"
    cd "$KODI_ADDON_REPO"

    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    git config user.signingkey "$REPO_SIGN_KEY_ID"
    git config commit.gpgsign true

    if [[ ! -d "$KODI_ADDON" ]]; then
      echo "$KODI_ADDON is new, no previous version found."

      mkdir "$KODI_ADDON"
      COMMIT_MESSAGE="(autodeploy) new $KODI_ADDON v.$KODI_ADDON_VERSION"
    else
      echo "$KODI_ADDON already exists, checking previous version..."

      OLD_VERSION=$(get_addon_version "$KODI_ADDON/addon.xml")

      if [[ "$OLD_VERSION" == "$KODI_ADDON_VERSION" ]]; then
        echo "New version $KODI_ADDON_VERSION is the same as existing one $OLD_VERSION"
        exit 1
      fi

      COMMIT_MESSAGE="(autodeploy) update $KODI_ADDON from v.$OLD_VERSION to v.$KODI_ADDON_VERSION"
    fi

    echo "Copying new files into repository..."
    cp "$KODI_ADDON_XML_PATH" "$KODI_ADDON"
    cp "$KODI_ADDON_ZIP_PATH" "$KODI_ADDON"

    echo "Rehashing repository XML..."
    python ../generate_addons_xml.py -o "addons.xml" ./

    echo "Generating MD5s..."
    generate_file_md5 "$KODI_ADDON/$KODI_ADDON_ZIP"
    generate_file_md5 "addons.xml"

    echo "Committing changes to repository..."
    git add -A
    git commit -m "$COMMIT_MESSAGE"
    git push

    echo "$KODI_ADDON v.$KODI_ADDON_VERSION has been successfully deployed to repository!"
    exit 0
    ;;
esac
