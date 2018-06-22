#!/bin/bash

# script to automate install of firefox nightly in linux
# btw i use arch
# done by R

# default install directory 
DIR=$USER/.bin
LANG="en-US"
URL="https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=$LANG"
ICON="https://wiki.mozilla.org/images/7/7a/Firefox-nightly_logo-only_RGB_25%25.png"


# help menu, for the less fortunate on the gene pool lotery
if [[ "$1" = "h" || "$1" = "help" ]]; then
   echo -e "\tScript to install Mozilla Firefox Nightly builds."
   echo -e "\tInstalls to $DIR."
   echo -e "\tDepedencies: wget, gnome desktop environment, imagemagick."
   echo -e "\tDownload url: $URL"
   echo -e "\tInstalling for user $USER"
   exit
fi

# check dependencies
if [ $( which convert > /dev/null ) ]; then
    echo "Error: ImageMagick not found. Exiting..."
    exit
fi
if [ $( which desktop-file-validate > /dev/null ) ]; then
    echo "Error: desktop-file-validate not found. Exiting..."
    exit
fi
if [ $( which wget  > /dev/null ) ]; then
    echo "Error: wget not found. Exiting..."
    exit
fi


# checking if directories exist already
if [ -d "$DIR" ]; then 
    if [ -d "$DIR/nightly" ]; then
        if [ -z "$(ls -A $DIR/nightly)" ]; then # check dir not empty
            echo "Installing to $DIR/nightly"
        else
            echo "Error: $DIR/nightly not empty. Exiting..." ; exit
        fi
    else 
        if [ $(mkdir $DIR/nightly > /dev/null) ]; then
            echo "Error: Can't create directory $DIR/nightly. Exiting..."
            exit
        fi
    fi

# creating necessary directories
else
    if [ $(mkdir $DIR > /dev/null) ]; then
        echo "Error: Can't create directory $DIR. Exiting..."
        exit
    fi
    if [ $(mkdir $DIR/nightly > /dev/null) ]; then
        echo "Error: Can't create directory $DIR/nightly. Exiting..."
        exit
    fi
fi

# checking for internet connection and availability of servers
if [ $(ping -c 5 www.mozilla.org > /dev/null) ]; then
    echo "Error: Can't reach Mozilla server. Exiting..."
    exit
fi

pushd $DIR

# download files
echo "Downloading files from $URL"
wget -O "firefox.tar.bz2" "$URL"
if [ $? -ne 0 ]; then
    echo "Error while retrieving files. Exiting..."
    exit
fi

# decompress file
echo "Decompressing file"
if [ $(tar xf "firefox.tar.bz2") ]; then
    echo "Error while decompressing files. Exiting..."
    exit
fi

if [ $(mv ./firefox/* ./nightly > /dev/null) ]; then
    echo "Error moving files. Exiting..."
    exit
fi

rmdir ./firefox/

push ./nightly

# download the fucking icon Mozilla won't bother to package together with the release
wget "$ICON" -O icon_raw.png

convert ./icon_raw.png -resize 128x128 ./icon.png
mv icon.png ./icons/

# create desktop file
cat << EOF > nightly.desktop
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

if [ $(desktop-file-validate nightly.desktop) ]; then
    echo "Error: desktop file not validated. Not installing. Exiting..."
    exit
else
    echo "Desktop file validated. Installing..."
    if [ $(desktop-file-install nightly.desktop --dir=~/.local/share/applications/) ]; then
        echo "Error: desktop file could not be validated. Exiting..."
    fi
fi

popd ; popd


echo "Done."

exit

