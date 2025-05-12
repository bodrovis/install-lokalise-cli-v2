# GitHub Action to Install Lokalise CLIv2

Not your father's CLI installer — this one's fast, flexible, and ready to Lokalise like a pro.

## Usage

```yaml
- name: Install Lokalise CLIv2
  uses: lokalise/install-lokalise-cli-v2@v1.2.1
  with:
    force-install: true         # Optional: force reinstallation even if already installed
    target-version: 3.1.3       # Optional: specify CLI version (e.g., 3.1.1). Defaults to latest.
```

## Parameters

- `target-version` *(optional)* — Version of the Lokalise CLI to install. Use the version number only (e.g., `3.1.1`), and do not include the `v` prefix. If not provided, the latest available version will be installed.
- `force-install` *(optional, default: `false`)* — Reinstall Lokalise CLI even if it is already installed.

## License

Apache license v2
