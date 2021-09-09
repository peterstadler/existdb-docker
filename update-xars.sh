#!/bin/bash
# echo welcome
echo
echo "#################################"
echo "# Welcome to the update-xars.sh #"
echo "#################################"
echo
echo "This script will fetch the latest versions of XARs for eXist-db."
echo "The target version of eXist-db has to be submitted as first argument."
echo "The URL of the repo from which to fetch the XARs can be submitted as"
echo "second parameter but will default to the eXist-db public repo at:"
echo "https://exist-db.org/exist/apps/public-repo/public"
echo
# check submitted arguments
echo "checking submitted arguments…"
echo
if [[ "$#" -eq 0 ]]
then
    echo "ERROR!"
    echo "You have to submit at least one argument indicating"
    echo "the target eXist-db version. For more information see:"
    echo "https://github.com/peterstadler/existdb-docker"
    echo
    exit
fi
# $VERSION is the eXist-db version
VERSION=$1
# $XAR_REPO_URL is the URL to the XAR repo where the XAR packages will be fetched
echo "setting XAR_REPO_URL to:"
if [[ "$#" -eq 2 ]]
then
    XAR_REPO_URL=$2
else
    XAR_REPO_URL=https://exist-db.org/exist/apps/public-repo/public
fi
echo "$XAR_REPO_URL"
echo

# list of package-names to fetch
# might get configurable in some future version
XAR_LIST=(dashboard eXide exist-documentation functx fundocs markdown monex packageservice semver-xq shared)

# create temporary download directory
echo "Creating temporary download folder at:"
DIR=`mktemp -d`
echo "$DIR"

#if $3 is existing directory use as PUBDIR, else create temporary directory
if [[ "$#" -ge 3 ]]
then
    if [[ -d "$3" ]]
    then
        echo "Setting target folder to existing folder:"
        PUBDIR=$3
    elif [[ "$3" != "" ]]
    then
        echo "Creating target folder at:"
        PUBDIR=`mkdir -p ${3}`
    fi
    echo "$PUBDIR"
fi

fetch_xar() {
    local ABBREV=$1
    local REPO=$2
    local FILENAME=$(xmllint --xpath "string(//app[abbrev='"$ABBREV"']/@path)" "$DIR"/apps.xml)
    echo "downloading $FILENAME from $REPO"
    curl -L -o "$DIR"/"$FILENAME" "$REPO"/"$FILENAME"
}

# remove existing XARs from autodeploy folder
# echo "Removing existing XARs from autodeploy folder."
# rm -f ${EXIST_HOME}/autodeploy/*.xar

echo "Fetching apps.xml from $XAR_REPO_URL"
curl -L -o "$DIR"/apps.xml "$XAR_REPO_URL"/apps.xml?version="$VERSION"

echo
echo "fetching XARs"
echo "============="
echo
echo "XARs will be written to $DIR"

for PKG in "${XAR_LIST[@]}"
do
    echo
    echo "------------------------"
    echo "processing $PKG"
    fetch_xar $PKG "$XAR_REPO_URL"
    echo "------------------------"
done

echo
echo "done fetching XARs"
echo
echo "XARs have been downloaded to: $DIR"

# Copy downloaded XARs from \$DIR to \$PUBDIR
if [[ -n "$PUBDIR" ]]
then
    if [[ "$4" == "prune" ]]
    then
        echo
        echo "Deleting existing XARs in:"
        echo "$PUBDIR"
        rm -f ${PUBDIR}/*.xar
    fi
    echo
    echo "Copying updated XARs to target directory:"
    echo "$PUBDIR"
    cp "$DIR"/*.xar $PUBDIR
    echo
    echo "Removing temporary download directory…"
    rm -Rf "$DIR"
fi
