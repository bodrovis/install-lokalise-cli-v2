#!/bin/bash

set -euo pipefail

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
            # Validate the installer
            if [[ -f "$INSTALLER_FILE" ]] && [[ $(head -n 1 "$INSTALLER_FILE") =~ ^#!/bin/sh ]]; then
                echo "Installer downloaded and validated successfully."
                return 0
            else
                echo "Installer validation failed. Content of the file:"
                cat "$INSTALLER_FILE" || echo "Unable to read file."
                rm -f "$INSTALLER_FILE"
            fi
        else
            echo "Failed to download installer. Retrying in $RETRY_DELAY seconds..."
        fi
        attempt=$((attempt + 1))
        sleep $((RETRY_DELAY ** attempt)) # Exponential backoff
    done

    echo "Failed to download a valid Lokalise CLI installer after $MAX_RETRIES attempts."
    exit 1
}

install_lokalise_cli() {
    trap 'rm -f "$INSTALLER_FILE"' EXIT

    download_installer

    echo "Running Lokalise CLI installer..."
    if ! bash "$INSTALLER_FILE"; then
        echo "Failed to install Lokalise CLI"
        exit 1
    fi

    rm -f "$INSTALLER_FILE"
    echo "Lokalise CLI installed successfully."

    validate_installation
}

validate_installation() {
    if ! command -v lokalise2 >/dev/null 2>&1; then
        echo "Error: Lokalise CLI installation failed. Command 'lokalise2' not found."
        exit 1
    fi

    echo "Lokalise CLI version: $(lokalise2 --version)"
}

if [[ "$FORCE_INSTALL" == "true" ]]; then
    install_lokalise_cli
elif ! command -v lokalise2 >/dev/null 2>&1; then
    install_lokalise_cli
else
    echo "Lokalise CLI is already installed, skipping installation."
fi
