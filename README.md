# Code Sign Action

This is a GitHub action that allows you to code sign files. It was developed specifically to code sign binaries built using [@lando/code-sign-action](https://github.com/marketplace/actions/code-sign-action) so it may not be appropriate for all use cases.

### Caveats

* Does not currently code sign on Linux

See [Advanced Usage](#advanced-usage) below for some examples of ^.

## Required Inputs

These keys must be set correctly for the action to work.

| Name | Description | Example Value |
|---|---|---|
| `file` | The file to sign.  | `bin/test` |
| `certificate-data` | A `base64` encoded string of your `p12` or `pfx` cert contents. | `SXQncyBkYW5nZXJvdXMgdG8gZ28gYWxvbmUhIFRha2UgdGhpcy4=` |
| `certificate-password` | The password to unlock the `certificate-data`. | `my-pass` |

## Optional Inputs

These keys are set to sane defaults but can be modified as needed.

| Name | Description | Default | Example |
|---|---|---|---|
| `apple-team-id` | **(Required)** for `macOS`. Does nothing on `linux` and `win`. The Apple Developer Program Team ID. | `null` | `FY8GAUX287` |

## Outputs

```yaml
outputs:
  file:
    description: "The path to the signed binary."
    value: ${{ steps.code-sign-action.outputs.file }}
```

##  Usage

### Basic Usage

**macOS**
```yaml
jobs:
  # Create raw unsigned binaries for win, mac, linux and on x64 and arm64
  package:
    runs-on: macos-11
  steps:
    name: Sign binary
    uses: lando/code-sign-action@v2
    with:
      file: path/to/binary
      certificate-data: ${{ secrets.APPLE_CERT_DATA }}
      certificate-password: ${{ secrets.APPLE_CERT_PASSWORD }}
      apple-team-id: ${{ secrets.APPLE_TEAM_ID }}
```

**Windows**
```yaml
jobs:
  # Create raw unsigned binaries for win, mac, linux and on x64 and arm64
  package:
    runs-on: windows-2022
  steps:
    name: Sign binary
    uses: lando/code-sign-action@v2
    with:
      file: path/to/binary
      certificate-data: ${{ secrets.WINDOZE_CERT_DATA }}
      certificate-password: ${{ secrets.WINDOZE_CERT_PASSWORD }}
```

## Changelog

We try to log all changes big and small in both [THE CHANGELOG](https://github.com/lando/code-sign-action/blob/main/CHANGELOG.md) and the [release notes](https://github.com/lando/code-sign-action/releases).

## Releasing

1. Correctly bump versions, tag things and push to GitHub

  ```bash
  yarn release
  ```

2. Publish to [GitHub Actions Marketplace](https://docs.github.com/en/enterprise-cloud@latest/actions/creating-actions/publishing-actions-in-github-marketplace)

## Contributors

<a href="https://github.com/lando/code-sign-action/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=lando/code-sign-action" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

## Other Resources

* [Important advice](https://www.youtube.com/watch?v=WA4iX5D9Z64)
