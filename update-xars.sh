#!/bin/bash
# echo welcome
echo
echo "#################################"
echo "# Welcome to the update-xars.sh #"
echo "#################################"
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
    echo "or execute with first argument being:"
    echo "help"
    echo
    exit
fi

if [[ "$1" == "help" ]]
then
    echo "You called help for using this script…"
    echo
    echo "########"
    echo "# HELP #"
    echo "########"
    echo
    echo 
    echo "This script will fetch the latest versions of XARs for eXist-db."
    echo "The target version of eXist-db has to be submitted as first argument."
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

# $VERSION is the eXist-db version
VERSION=$1

# Set list of package-names to fetch
if [[ "$#" -ge 2 ]]
then
    XAR_LIST=($2)
else
    XAR_LIST=(dashboard eXide exist-documentation functx fundocs markdown monex packageservice semver-xq shared)
fi

# $XAR_REPO_URL is the URL to the XAR repo where the XAR packages will be fetched
echo "setting XAR_REPO_URL to:"
if [[ "$#" -ge 3 ]]
then
    XAR_REPO_URL=$3
else
    XAR_REPO_URL=https://exist-db.org/exist/apps/public-repo/public
fi
echo "$XAR_REPO_URL"
echo

# create temporary download directory
echo "Creating temporary download directory at:"
DIR=`mktemp -d`
echo "$DIR"

#if $4 is existing directory use as PUBDIR, else create temporary directory
if [[ "$#" -ge 4 ]]
then
    if [[ -d "$4" ]]
    then
        echo "Setting target folder to existing folder:"
        PUBDIR=$4
    elif [[ "$4" != "" ]]
    then
        echo "Creating target folder at:"
        PUBDIR=`mkdir -p ${4}`
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
    fetch_xar "$PKG" "$XAR_REPO_URL"
    echo "------------------------"
done

echo
echo "done fetching XARs"
echo
echo "XARs have been downloaded to: $DIR"

# Copy downloaded XARs from \$DIR to \$PUBDIR
if [[ -n "$PUBDIR" ]]
then
    if [[ "$5" == "prune" ]]
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
