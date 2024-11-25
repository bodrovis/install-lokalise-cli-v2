#!/bin/bash

set -e

FORCE_INSTALL="${FORCE_INSTALL:-false}"
INSTALLER_URL="https://raw.githubusercontent.com/lokalise/lokalise-cli-2-go/master/install.sh"
INSTALLER_FILE="install.sh"
MAX_RETRIES=3
RETRY_DELAY=3

download_installer() {
    local attempt=1

    while [[ $attempt -le $MAX_RETRIES ]]; do
        echo "Downloading Lokalise CLI installer, attempt $attempt..."
        if curl -sfLO "$INSTALLER_URL"; then
            if [[ -f "$INSTALLER_FILE" ]] && [[ $(head -n 1 "$INSTALLER_FILE") =~ ^#!/bin/sh ]]; then
                return 0
            else
                echo "Installer validation failed. Retrying..."
                rm -f "$INSTALLER_FILE"
            fi
        else
            echo "Failed to download installer. Retrying in $RETRY_DELAY seconds..."
        fi
        attempt=$((attempt + 1))
        sleep $RETRY_DELAY
    done

    echo "Failed to download a valid Lokalise CLI installer after $MAX_RETRIES attempts."
    exit 1
}

install_lokalise_cli() {
    download_installer

    echo "Running Lokalise CLI installer..."
    sh "$INSTALLER_FILE" || {
        echo "Failed to install Lokalise CLI"
        exit 1
    }

    rm "$INSTALLER_FILE"
    echo "Lokalise CLI installed successfully."
}

if [[ "$FORCE_INSTALL" == "true" ]]; then
    install_lokalise_cli
elif ! command -v lokalise2 >/dev/null 2>&1; then
    install_lokalise_cli
else
    echo "Lokalise CLI is already installed, skipping installation."
fi
