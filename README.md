# GitHub Action to Install Lokalise CLIv2

Not your father's CLI installer: install Lokalise CLIv2 for maximum fun and productivity!

## Usage

```yaml
- name: Install Lokalise CLIv2
  uses: bodrovis/install-lokalise-cli-v2@v1.1.0
  # Optionally, provide parameters:
  with:
    force-install: true
```

## Parameters

* `force-install` — reinstall Lokalise CLIv2 even if it is already installed. Defaults to `false`.

## License

Apache license v2