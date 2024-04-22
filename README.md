# Code Sign Action

This is a GitHub action that allows you to code sign files. It was developed specifically to code sign binaries built using [@lando/pkg-action](https://github.com/marketplace/actions/pkg-action) so it may not be appropriate for all use cases. It also can do basic [mac OS notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).

### Caveats

* Does not currently code sign on Linux
* Does not staple the notarized file
* You may need to set `options: --options runtime --entitlements entitlements.xml` for notarization to work correctly

## Required Inputs

These keys must be set correctly for the action to work.

| Name | Description | Example Value |
|---|---|---|
| `file` | The file to sign.  | `bin/test` |
| `certificate-data` | A `base64` encoded string of your `p12` or `pfx` cert contents. | `${{ secrets.APPLE_CERT_DATA }}` |
| `certificate-password` | The password to unlock the `certificate-data`. | `${{ secrets.APPLE_CERT_PASSWORD }}` |

## Optional Inputs

These keys are set to sane defaults but can be modified as needed.

| Name | Description | Default | Example |
|---|---|---|---|
| `apple-notary-user` | **(Required)** for `macOS` notarization. Does nothing on `linux` and `win`. The Apple Developer account email to use in notarization. | `null` | `${{ secrets.APPLE_NOTARY_USER }}` |
| `apple-notary-password` | **(Required)** for `macOS` notarization. Does nothing on `linux` and `win`. The Apple Developer account password to use in notarization. | `null` | `${{ secrets.APPLE_NOTARY_PASSWORD }}` |
| `apple-notary-tool` | The `xcrun` tool to use for notarization. Does nothing on `linux` and `win`. | `notarytool` | `altool` |
| `apple-product-id` | **(Required)** for `macOS` notarization. Does nothing on `linux` and `win`. The Apple Developer Product ID to use in notarization. | `null` | `dev.lando.code-sign-action` |
| `apple-team-id` | **(Required)** for `macOS`. Does nothing on `linux` and `win`. The Apple Developer Program Team ID. | `null` | `FY8GAUX287` |
| `keylocker-host` | The host of the KeyLocker host (DigiCert One). Adding this value is **required** to sign `win` with DigiCert KeyLocker. Adding this value will disable signing `win` via SignTool. | `null` | `https://clientauth.one.digicert.com`|
| `keylocker-api-key` | API key for the KeyLocker host. | `null` | `${{ secrets.KEYLOCKER_API_KEY }}` |
| `keylocker-cert-sha1-hash` | SHA1 hash for the KeyLocker host. | `null` | `${{ secrets.KEYLOCKER_CERT_SHA1_HASH }}` |  
| `options` | Additional options to pass to the signing tool. | `null` | `--options runtime --entitlements entitlements.xml` |

## Outputs

```yaml
outputs:
  file:
    description: "The path to the signed and/or notarized file."
    value: ${{ steps.code-sign-action.outputs.file }}
```

##  Usage

### Basic Usage

**macOS**

```yaml
jobs:
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

**macOS with notarization**

```yaml
jobs:
  package:
    runs-on: macos-11
  steps:
    name: Sign binary
    uses: lando/code-sign-action@v2
    with:
      file: path/to/binary
      certificate-data: ${{ secrets.APPLE_CERT_DATA }}
      certificate-password: ${{ secrets.APPLE_CERT_PASSWORD }}
      apple-notary-user: ${{ secrets.APPLE_NOTARY_USER }}
      apple-notary-password: ${{ secrets.APPLE_NOTARY_PASSWORD }}
      apple-notary-tool: altool
      apple-team-id: FY8GAUX282
      apple-product-id: dev.lando.code-sign-action
      options: --options runtime --entitlements entitlements.xml
```

**Windows**

```yaml
jobs:
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

** Windows with DigiCert KeyLocker**

```yaml
jobs:
  package:
    runs-on: windows-2022
  steps:
    name: Sign binary
    uses: lando/code-sign-action@v2
    with:
      file: path/to/binary
      certificate-data: ${{ secrets.WINDOZE_CERT_DATA }}
      certificate-password: ${{ secrets.WINDOZE_CERT_PASSWORD }}
      keylocker-host: ${{ secrets.KEYLOCKER_HOST }}
      keylocker-api-key: ${{ secrets.KEYLOCKER_API_KEY }}
      keylocker-cert-sha1-hash: ${{ secrets.KEYLOCKER_CERT_SHA1_HASH }}
```



## Changelog

We try to log all changes big and small in both [THE CHANGELOG](https://github.com/lando/code-sign-action/blob/main/CHANGELOG.md) and the [release notes](https://github.com/lando/code-sign-action/releases).

## Releasing

Create a release and publish to [GitHub Actions Marketplace](https://docs.github.com/en/enterprise-cloud@latest/actions/creating-actions/publishing-actions-in-github-marketplace). Note that the release tag must be a [semantic version](https://semver.org/).

## Maintainers

* [@pirog](https://github.com/pirog)
* [@reynoldsalec](https://github.com/reynoldsalec)

## Contributors

<a href="https://github.com/lando/code-sign-action/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=lando/code-sign-action" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

## Other Resources

* [Important advice](https://www.youtube.com/watch?v=WA4iX5D9Z64)
