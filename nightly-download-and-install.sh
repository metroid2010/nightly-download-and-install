#!/bin/bash

# script to automate install of firefox nightly in linux
# btw i use arch
# done by R

# default install directory 
DIR="/home/$USER/.bin"

VERSION="v0.1, by R"
LANG="en-US"
URL="https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=$LANG"
ICON="https://wiki.mozilla.org/images/7/7a/Firefox-nightly_logo-only_RGB_25%25.png"


while [ $# -gt 0 ]; do
   case "$1" in
      -h|--help)
         get_help
         ;;
      -v)
         echo "$VERSION"
         ;;
      *)
         echo "Flag $1 not recognised"
         get_help
         ;;
   esac
done


# help menu, for the less fortunate of the gene pool lotery
function get_help {
   echo -e "\tScript to install Mozilla Firefox Nightly builds."
   echo -e "\tInstalls to $DIR."
   echo -e "\tDepedencies: wget, gnome desktop environment, imagemagick."
   echo -e "\tDownload url:\n\t\t$URL"
   echo -e "\tInstalling for user $USER"

   exit 1
}

function check_deps {
    if [ "$(hash convert > /dev/null)" ] ; then
        echo "Error: ImageMagick not found. Exiting..."
        exit 1
    fi
    if  [ "$(hash desktop-file-validate > /dev/null)" ] ; then
        echo "Error: desktop-file-validate not found. Exiting..."
        exit 1
    fi
    if  [ "$(hash wget  > /dev/null)" ] ; then
        echo "Error: wget not found. Exiting..."
        exit 1
    fi
}

check_deps

# checking if directories exist already
if [ -d "$DIR" ]; then 
    if [ -d "$DIR/nightly" ]; then
        if [ ! "$(ls -A "$DIR/nightly")" ]; then # check dir not empty
            echo "Installing to $DIR/nightly"
        else
            echo "Error: $DIR/nightly not empty. Exiting..."
            exit 1
        fi
    else 
        if [ "$(mkdir "$DIR/nightly" > /dev/null)" ] ; then
            echo "Error: Can't create directory $DIR/nightly. Exiting..."
            exit 1
        else
            echo "Create directory $DIR/nightly"
        fi
    fi

# creating necessary directories
else
    if  $(mkdir $DIR > /dev/null) ; then
        echo "Error: Can't create directory $DIR. Exiting..."
        exit 1
    fi
    if [ "$(mkdir "$DIR/nightly" > /dev/null)" ]; then
        echo "Error: Can't create directory $DIR/nightly. Exiting..."
        exit 1
    fi
fi

# checking for internet connection and availability of servers
if [ "$(ping -c 5 www.mozilla.org > /dev/null)" ]; then
    echo "Error: Can't reach Mozilla server. Exiting..."
    exit 1
else
    echo "Mozilla server reached."
fi

pushd "$DIR"

# download files
echo "Downloading files from $URL"
wget -O "firefox.tar.bz2" "$URL"
if [ "$?" -ne "0" ]; then
    echo "Error while retrieving files. Exiting..."
    exit 1
fi

##TODO : CHECKSUM

# decompress file
echo "Decompressing files"
if [ "$(tar xf "firefox.tar.bz2")" ]; then
    echo "Error while decompressing files. Exiting..."
    exit 1
else
    echo "Files successfully decompressed"
fi

if [ "$(mv $DIR/firefox/* $DIR/nightly > /dev/null)" ]; then
    echo "Error moving files. Exiting..."
    exit 1
fi

rmdir "$DIR/firefox"

pushd "$DIR/nightly"

# download the fucking icon Mozilla won't bother to package together with the release
pushd "$DIR/nightly/icons"
wget -O "icon_raw.png" "$ICON"
convert "icon_raw.png" -resize 128x128 "icon.png" # original is too big for a thumbnail
popd

echo "Creating desktop file in $(pwd)"
# create desktop file
cat << EOF > "nightly.desktop"
[Desktop Entry]
Type=Application
Name=Firefox Nightly
Comment=Nightly builds of Mozilla Firefox
Exec=$DIR/nightly/firefox %u
Terminal=false
Categories=Network;WebBrowser;
GenericName=Web Browser
Icon=$DIR/nightly/icons/icon.png
EOF

if [ "$(desktop-file-validate nightly.desktop)" ] ; then
    echo "Error: desktop file not validated. Not installing. Exiting..."
    exit 1
else
    echo "Desktop file validated. Installing..."
    if [ "$(desktop-file-install nightly.desktop --dir="/home/$USER/.local/share/applications/")" ]; then
        echo "Error: desktop file could not be installed. Exiting..."
        exit 1
    fi
fi

popd ; popd

echo "Done."

exit 0
