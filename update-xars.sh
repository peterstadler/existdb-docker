#!/bin/bash

#
# Copyright 2021 Benjamin W. Bohl
#
# Licensed under the terms of the MIT License (MIT):
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

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

# define function for echoing help for update-xars.sh
echo_help() {
    echo
    echo "########"
    echo "# ${b}HELP${n} #"
    echo "########"
    echo
    echo "This script will fetch the latest versions of XARs for eXist-db."
    echo "The target version of eXist-db has to be submitted with the ${b}-v${n} option."
    echo
    echo "The following options are available:"
    echo
    echo "    ${b}-v${n}    [version][as semantic version]"
    echo "          indicates the eXist-db version you want to fetch the XARs for, e.g.:"
    echo "              -v 5.2.0"
    echo
    echo "    ${b}-r${n}    [repository][as URL]"
    echo "          indicated the repository URL to fetch the XARs from, will default to the eXist-db public repo at:"
    echo "          https://exist-db.org/exist/apps/public-repo/public"
    echo
    echo "    ${b}-d${n}    [directory][as relative or absolute system file path]"
    echo "          indicates the the directory the fetched XARs should be copiped to after finishing all downloads."
    echo "          If not specified, the XARs will be written to a system temporary directory, the location of which"
    echo "          will be echoed at the end of the script."
    echo
    echo "    ${b}-p${n}    [prune]"
    echo "          if set all XAR files in the directory submitted with ${b}-d${n} will be deleted,"
    echo "          before the fetched XARs are being moved there."
    echo
    echo "    ${b}-x${n}    [XAR-list][as whitespace-separated string-array]"
    echo "          lists the shortnames of the XARs to fetch, will default to:"
    echo "          \"dashboard eXide exist-documentation functx fundocs markdown monex packageservice semver-xq shared\""
    echo
    echo "    ${b}-h${n}    [help]"
    echo "          displays this help."
    echo
    echo
    echo "EXAMPLE USAGE"
    echo "============="
    echo
    echo "1. \$ ./update-xars.sh"
    echo "---------------------"
    echo
    echo "Will raise an error and prompt an error message."
    echo
    echo
    echo "2. \$ ./update-xars.sh -h"
    echo "------------------------"
    echo
    echo "Prompts this help."
    echo
    echo
    echo "3. \$ ./update-xars.sh -v 5.2.0"
    echo "------------------------------"
    echo
    echo "Will download the latest XAR versions for eXist-db version 5.2.0."
    echo "The XARs will be downloaded to a system temporary directory."
    echo "The location of the temporary directory will be prompted at the end of the script."
    echo
    echo
    echo "3. \$ ./update-xars.sh -v 5.2.0 -x \"dashboard eXide\""
    echo "---------------------------------------------------"
    echo
    echo "The second argument is to be passed in as string array. It can be"
    echo "used to specify the abbreviated package-names of the XARs to fetch."
    echo
    echo
    echo "4. \$ ./update-xars.sh -v 5.2.0 -x \"dashboard eXide\" -r https://your-custom-repo-url/public"
    echo "------------------------------------------------------------------------------------------"
    echo
    echo "Same as 2. but the XARs will be fetched from https://your-custom-repo-url/public."
    echo
    echo
    echo "5. \$ ./update-xars.sh -v 5.2.0 -x \"dashboard eXide\" -r https://your-custom-repo-url/public -d ./your/custom/target/directory"
    echo "----------------------------------------------------------------------------------------------------------------------------"
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
    echo "5. \$ ./update-xars.sh -v 5.2.0 -x \"dashboard eXide\" -r https://your-custom-repo-url/public -d ./your/custom/target/directory -p"
    echo "-------------------------------------------------------------------------------------------------------------------------------"
    echo
    echo "If you submit \"prune\" as fifth argument ./your/custom/target/directory will"
    echo "be pruned of any existing XARs, before the newly fetched XARs ar copied to location."
}

# echo welcome
echo
echo "#################################"
echo "# ${b}Welcome to the update-xars.sh${n} #"
echo "#################################"
echo
echo "This script will fetch the latest versions of XARs for eXist-db."
echo "The target version of eXist-db has to be submitted with the -v option."
echo
echo "This script has been called with the following options:"
echo
echo "VERSION of eXist-db: $VERSION"
echo "REPO_URL for fetching XARs: $REPO_URL"
echo "XAR_LIST being XAR abbreviated names to fetch: ${XAR_LIST[@]}"
echo "PUBDIR directory in which to place the fetched XARs: $PUBDIR"
echo "HELP for showing documentation: $HELP"
echo

# if help is set echo help and exit script
if [[ $HELP = true ]]
then
    echo_help
    exit
fi

# check for version
if [[ -z $VERSION ]]
then
    echo "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠"
    echo "                                       ${b}ERROR!${n}                              "
    echo "You have to submit at least the ${b}-v${n} [version] indicating the target eXist-db version."
    echo "For more information see:"
    echo "  https://github.com/peterstadler/existdb-docker"
    echo "  or execute this script with the ${b}-h${n} [help] option."
    echo "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠"
    echo
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

#define function for fetching a given XAR from REPO
fetch_xar() {
    local ABBREV=$1
    local REPO=$2
    local FILENAME=$(xmllint --xpath "string(//app[abbrev='"$ABBREV"']/@path)" "$DIR"/apps.xml)
    echo "downloading $FILENAME from $REPO"
    curl -L -o "$DIR"/"$FILENAME" "$REPO"/"$FILENAME"
    if test -f "$DIR"/"$FILENAME"; then
        echo "download successful"
    else
        echo "error downloading XAR"
        exit
    fi
}

# fetch apps.xml from repo for \$VERSION
echo
echo "Fetching apps.xml"
echo "================="
echo "from $REPO_URL"
echo
curl -L -o "$DIR"/apps.xml "$REPO_URL"/apps.xml?version="$VERSION"

# fetch the XARs
echo
echo "fetching XARs"
echo "============="
echo "XARs will be downloaded to:"
echo "$DIR"

# iteerate over \$XAR_LIST
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

# Copy downloaded XARs from \$DIR to \$PUBDIR if \$PUBDIR is set
if [[ -n "$PUBDIR" ]]
then
    mkdir -p ${PUBDIR}
    echo "Assured presence of target directory at:"
    echo "$PUBDIR"
    # if prune is set then delete all xars from target directory before copying
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
