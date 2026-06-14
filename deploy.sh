#!/bin/bash

PLUGIN_PATH=$HOME/.local/share/noctalia/plugins
PLUGIN_OWNER=davidgape89
PLUGIN_NAME=dnf-updates

# --- Color Codes for Pretty Output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Disabling plugin"

noctalia msg plugins disable $PLUGINOWNER/$PLUGIN_NAME

echo -e "${GREEN}Starting deployment...${NC}"
echo "-----------------------------------------------"

if [ -d "$PLUGIN_PATH/$PLUGIN_NAME" ]; then
	echo "Folder already exists, removing..."
	rm -rf "${PLUGIN_PATH}/${PLUGIN_NAME}"
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}[SUCCESS]${NC} Removed folder successfully."
	else
		echo -e "${RED}[ERROR]${NC} There was a problem removing the folder, exiting."
		exit 1
	fi
else
	echo "Folder does not exist, proceeding with deployment."
fi

cd ../
cp -r "${PLUGIN_NAME}" "${PLUGIN_PATH}"

if [ $? -eq 0 ]; then
	echo -e "${GREEN}[SUCCESS]${NC} Deployed the plugin successfully."
else
	echo -e "${RED}[ERROR]${NC} There was a problem deploying the plugin."
	exit 1
fi

echo -e "${GREEN}[SUCCESS]${NC} Plugin deployed successfully."

# echo "Enabling plugin now..."

# noctalia msg plugins enable $PLUGIN_OWNER/$PLUGIN_NAME

# if [ $? -eq 0 ]; then
#     echo -e "${GREEN}[SUCCESS]${NC} Plugin up and running."
# else
#     echo -e "${RED}[ERROR]${NC} There was a problem enabling the plugin."
#     exit 1
# fi
