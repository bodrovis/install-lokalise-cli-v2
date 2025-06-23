#!/bin/bash
set -euo pipefail

FORCE_INSTALL="${FORCE_INSTALL:-false}"
ADD_TO_PATH="${ADD_TO_PATH:-false}"
INSTALLER_URL="https://raw.githubusercontent.com/lokalise/lokalise-cli-2-go/8ba6bbed2637cf615dd97496e99828f92a1817d7/install.sh"

BIN_DIR="${BIN_DIR:-./bin}"
LOKALISE_CLI="$BIN_DIR/lokalise2"
MAX_RETRIES=3
RETRY_DELAY=3

mkdir -p "$BIN_DIR"

INSTALLER_FILE=$(mktemp)
export INSTALLER_FILE

cleanup() {
    rm -f "$INSTALLER_FILE"
}
trap cleanup EXIT

download_installer() {
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        echo "Downloading Lokalise CLI installer, attempt $attempt..."
        
        if curl -sfLo "$INSTALLER_FILE" "$INSTALLER_URL"; then
            # Validate installer: non-empty and starts with #!/bin/sh
            if [[ -s "$INSTALLER_FILE" ]] && head -n 1 "$INSTALLER_FILE" | grep -q "^#!/bin/sh"; then
                echo "Installer downloaded and validated successfully."
                return 0
            else
                echo "Installer validation failed. File content:"
                if ! cat "$INSTALLER_FILE"; then
                    echo "Unable to read downloaded file (permission or FS issue?)"
                fi
                rm -f "$INSTALLER_FILE"
                # Recreate temp file for next attempt
                INSTALLER_FILE=$(mktemp)
            fi
        else
            echo "Failed to download installer."
        fi
        
        local delay=$((RETRY_DELAY * attempt))
        echo "Retrying in $delay seconds..."
        sleep "$delay"
        attempt=$((attempt + 1))
    done

    echo "Failed to download a valid Lokalise CLI installer after $MAX_RETRIES attempts."
    exit 1
}

install_lokalise_cli() {
    download_installer

    TAG_ARG=""
    if [[ -n "${LOKALISE_CLI_VERSION:-}" ]]; then
        TAG_ARG="v${LOKALISE_CLI_VERSION}"
    fi

    if [[ -n "${TAG_ARG}" ]]; then
        echo "Installing Lokalise CLI version: $TAG_ARG"
    else
        echo "Installing latest version of Lokalise CLI"
    fi
    if ! bash "$INSTALLER_FILE" -b "$BIN_DIR" "$TAG_ARG"; then
        echo "Failed to install Lokalise CLI"
        exit 1
    fi

    echo "Lokalise CLI installed successfully."
    validate_installation
    add_to_path
}

validate_installation() {
    if [[ ! -x "$LOKALISE_CLI" ]]; then
        echo "Error: Lokalise CLI installation failed. Command '$LOKALISE_CLI' not found or not executable."
        exit 1
    fi

    echo "Lokalise CLI version: $("$LOKALISE_CLI" --version)"
}

add_to_path() {
    shopt -s nocasematch
    if [[ "$ADD_TO_PATH" == "true" ]]; then
        local bin_abs_path
        bin_abs_path="$(cd "$BIN_DIR" && pwd)"
        
        if [[ -z "${GITHUB_PATH:-}" ]]; then
            echo "Warning: GITHUB_PATH not set, cannot persist PATH for future steps."
            echo "You may want to add $bin_abs_path to PATH manually."
        else
            echo "Adding $bin_abs_path to PATH for subsequent workflow steps."
            echo "$bin_abs_path" >> "$GITHUB_PATH"
        fi
    fi
}

shopt -s nocasematch
if [[ "$FORCE_INSTALL" == "true" ]]; then
    echo "Force install enabled. Proceeding with installation."
    install_lokalise_cli
elif [[ ! -x "$LOKALISE_CLI" ]]; then
    install_lokalise_cli
else
    echo "Lokalise CLI is already installed at $LOKALISE_CLI, skipping installation."
    add_to_path
fi
