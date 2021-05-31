#!/bin/bash
VERSION=$1
XAR_REPO_URL=$2
XAR_LIST=(dashboard eXide exist-documentation functx fundocs markdown monex packageservice semver-xq shared)
DIR=`mktemp -d`

fetch_xar() {
    local ABBREV=$1
    local REPO=$2
    local FILENAME=$(xmllint --xpath "string(//app[abbrev='"$ABBREV"']/@path)" "$DIR"/apps.xml)
    echo "downloading $FILENAME from $REPO"
    curl -L -o "$DIR"/"$FILENAME" "$REPO"/"$FILENAME"
}

# remove existing XARs from autodeploy folder
rm -f ${EXIST_HOME}/autodeploy/*.xar

echo " fetch apps.xml from " "$XAR_REPO_URL"
curl -L -o "$DIR"/apps.xml "$XAR_REPO_URL"/apps.xml?version="$VERSION"

echo "fetch XARs"
echo "=========="
echo
echo "writing to $DIR"

for PKG in "${XAR_LIST[@]}"
do
    echo
    echo "processing $PKG"
    fetch_xar $PKG "$XAR_REPO_URL"
done

echo "done fetching XARs"
echo
echo "copy updated XARs to autodeploy folder"
cp "$DIR"/*.xar ${EXIST_HOME}/autodeploy/

# delete temporary dir
rm -Rf "$DIR" 
