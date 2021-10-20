#!/bin/bash

# parse submitted options
while getopts ":v:r:d:px:h" opt; do
  case $opt in
    v) VERSION="$OPTARG"
    ;;
    r) REPO_URL="$OPTARG"
    ;;
    d) PUBDIR="$OPTARG"
    ;;
    p) PRUNE=true
    ;;
    x) XAR_LIST=($OPTARG)
    ;;
    h) HELP=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

#define typefaces
b=$(tput bold)
n=$(tput sgr0)

# echo welcome
echo
echo "#################################"
echo "# Welcome to the update-xars.sh #"
echo "#################################"
echo
echo "This script has been called with the following options:"
echo
echo "VERSION of eXist-db: $VERSION"
echo "REPO_URL for fetching XARs: $REPO_URL"
echo "XAR_LIST being XAR abbreviated names to fetch: ${XAR_LIST[@]}"
echo "PUBDIR directory in which to place the fetched XARs: $PUBDIR"
echo "HELP for showing documentation: $HELP"

# check for version
if [[ -z $VERSION ]]
then
    echo "ERROR!"
    echo "You have to submit at least the version \(-v\) indicating"
    echo "the target eXist-db version. For more information see:"
    echo "https://github.com/peterstadler/existdb-docker"
    echo "or execute this script with the help option \(-h\)."
    echo ""
    exit
fi

if [[ $HELP = true ]]
then
    echo "You called help for using this script…"
    echo
    echo "########"
    echo "# HELP #"
    echo "########"
    echo
    echo 
    echo "This script will fetch the latest versions of XARs for eXist-db."
    echo "The target version of eXist-db has to be submitted with the -v option."
    echo
    echo "The following options are available:"
    echo
    echo "TODO"
    echo
    echo "The URL of the repo from which to fetch the XARs can be submitted as"
    echo "second argument but will default to the eXist-db public repo at:"
    echo "https://exist-db.org/exist/apps/public-repo/public"
    echo
    echo "A folder location can be submitted as third argument. The downloaded"
    echo "XARs will be copied to this location after completing all downloads."
    echo "Please be aware that you will have to submit the repo URL as second"
    echo "argument if you want to specify a target folder!"
    echo
    echo "EXAMPLE USAGE"
    echo "============="
    echo
    echo "1. \$ ./update-xars.sh"
    echo "-------------------"
    echo
    echo "Will raise an error and prompt an error message."
    echo
    echo
    echo "2. \$ ./update-xars.sh help"
    echo "-------------------"
    echo
    echo "Prompts this help."
    echo
    echo
    echo "3. \$ ./update-xars.sh 5.2.0"
    echo "-------------------------"
    echo
    echo "Will download the latest XAR versions for eXist-db version 5.2.0."
    echo "The XARs will be downloaded to a system temporary directory."
    echo "The location of the temporary directory will be prompted at the end of the script."
    echo
    echo
    echo "3. \$ ./update-xars.sh 5.2.0 \"dashboard eXide\""
    echo "----------------------------------------------------------------"
    echo
    echo "The second argument is to be passed in as string array. It can be"
    echo "used to specify the abbreviated package-names of the XARs to fetch."
    echo
    echo
    echo "4. \$ ./update-xars.sh 5.2.0 \"dashboard eXide\" https://your-custom-repo-url/public"
    echo "------------------------------------------------------------------------------------"
    echo
    echo "Same as 2. but the XARs will be fetched from https://your-custom-repo-url/public."
    echo
    echo
    echo "5. \$ ./update-xars.sh 5.2.0 \"dashboard eXide\" https://your-custom-repo-url/public ./your/custom/target/directory"
    echo "-------------------------------------------------------------------------------------------------------------------"
    echo
    echo "Same as 3. but the downloaded XARs will be copied to ./your/custom/target/directory"
    echo "after downloading has finished."
    echo
    echo "If ./your/custom/target/directory does not already exist, it will be created by this script."
    echo
    echo "Please be aware that ./your/custom/target/directory may already contain"
    echo "other files. Theses could interfere when using the directory as autodeploy"
    echo "directory with eXist-db. If you want to prune the directory's contents before"
    echo "copying the newly downloaded XARs, please submit 'prune' as fourth argument."
    echo 
    echo 
    echo "5. \$ ./update-xars.sh 5.2.0 \"dashboard eXide\" https://your-custom-repo-url/public ./your/custom/target/directory prune"
    echo "-------------------------------------------------------------------------------------------------------------------------"
    echo
    echo "If you submit \"prune\" as fifth argument ./your/custom/target/directory will"
    echo "be pruned of any existing XARs, before the newly fetched XARs ar copied to location."
    exit
fi

# Set list of package-names to fetch
if [[ ${#XAR_LIST[@]} == 0 ]]
then 
    XAR_LIST=(dashboard eXide exist-documentation functx fundocs markdown monex packageservice semver-xq shared)
    echo "Defaulted XAR_LIST to: ${XAR_LIST[*]}"
fi

# $REPO_URL is the URL to the XAR repo where the XAR packages will be fetched
if [[ -z "$REPO_URL" ]]
then
    REPO_URL=https://exist-db.org/exist/apps/public-repo/public
    echo "Defaulted REPO_URL to: $REPO_URL"
fi

# create temporary download directory
echo "Creating temporary download directory at:"
DIR=`mktemp -d`
echo "$DIR"

fetch_xar() {
    local ABBREV=$1
    local REPO=$2
    local FILENAME=$(xmllint --xpath "string(//app[abbrev='"$ABBREV"']/@path)" "$DIR"/apps.xml)
    echo "downloading $FILENAME from $REPO"
    curl -L -o "$DIR"/"$FILENAME" "$REPO"/"$FILENAME"
}

echo
echo "Fetching apps.xml"
echo "================="
echo "from $REPO_URL"
echo
curl -L -o "$DIR"/apps.xml "$REPO_URL"/apps.xml?version="$VERSION"

echo
echo "fetching XARs"
echo "============="
echo "XARs will be downloaded to:"
echo "$DIR"

for PKG in "${XAR_LIST[@]}"
do
    echo
    echo "------------------------"
    echo "processing $PKG"
    fetch_xar "$PKG" "$REPO_URL"
    echo "------------------------"
done

echo
echo "done fetching XARs"
echo
echo "XARs have been downloaded to:"
echo "$DIR"

# Copy downloaded XARs from \$DIR to \$PUBDIR
if [[ -n "$PUBDIR" ]]
then
    mkdir -p ${PUBDIR}
    echo "Assured presence of target directory at:"
    echo "$PUBDIR"
    if [[ $PRUNE = true ]]
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
