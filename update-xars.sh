#!/bin/bash
VERSION=$1
DIR=$2

REPO=https://exist-db.org/exist/apps/public-repo/public

if [ "$DIR" != "" ]
then
    mkdir -p "$DIR"
else
    echo DIR not provided as second argument
    exit;
fi

if [ "$VERSION" != "" ]
then
    curl -L -o "$DIR"/apps.xml "$REPO"/apps.xml?version="$VERSION"
    DB=$(xmllint --xpath "string(//app[abbrev='dashboard']/@path)" "$DIR"/apps.xml)
    echo "$DB"
    curl -L -o "$DIR"/"$DB" "$REPO"/"$DB"
    FUNCTX=$(xmllint --xpath "string(//app[abbrev='functx']/@path)" "$DIR"/apps.xml)
    echo "$FUNCTX"
    curl -L -o "$DIR"/"$FUNCTX" "$REPO"/"$FUNCTX"
    PKG=$(xmllint --xpath "string(//app[abbrev='packageservice']/@path)" "$DIR"/apps.xml)
    echo "$PKG"
    curl -L -o "$DIR"/"$PKG" "$REPO"/"$PKG"
    MONEX=$(xmllint --xpath "string(//app[abbrev='monex']/@path)" "$DIR"/apps.xml)
    echo "$MONEX"
    curl -L -o "$DIR"/"$MONEX" "$REPO"/"$MONEX"
    SHARED=$(xmllint --xpath "string(//app[abbrev='shared']/@path)" "$DIR"/apps.xml)
    echo "$SHARED"
    curl -L -o "$DIR"/"$SHARED" "$REPO"/"$SHARED"
    SEMVER=$(xmllint --xpath "string(//app[abbrev='semver-xq']/@path)" "$DIR"/apps.xml)
    echo "$SEMVER"
    curl -L -o "$DIR"/"$SEMVER" "$REPO"/"$SEMVER"
    EXIDE=$(xmllint --xpath "string(//app[abbrev='eXide']/@path)" "$DIR"/apps.xml)
    echo "$EXIDE"
    curl -L -o "$DIR"/"$EXIDE" "$REPO"/"$EXIDE"
    MD=$(xmllint --xpath "string(//app[abbrev='markdown']/@path)" "$DIR"/apps.xml)
    echo "$MD"
    curl -L -o "$DIR"/"$MD" "$REPO"/"$MD"
    DOC=$(xmllint --xpath "string(//app[abbrev='exist-documentation']/@path)" "$DIR"/apps.xml)
    echo "$DOC"
    curl -L -o "$DIR"/"$DOC" "$REPO"/"$DOC"
    FUNDOC=$(xmllint --xpath "string(//app[abbrev='fundocs']/@path)" "$DIR"/apps.xml)
    echo "$FUNDOC"
    curl -L -o "$DIR"/"$FUNDOC" "$REPO"/"$FUNDOC"
else
    echo VERSION not set
fi
