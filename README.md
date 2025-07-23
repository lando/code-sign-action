# Code Sign Action

This is a GitHub action that allows you to code sign binary files.

It was developed specifically to code sign binaries built using [@lando/pkg-action](https://github.com/marketplace/actions/pkg-action) so it may not be appropriate for all use cases. It also can do basic [macOS notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).

It will automatically set the `signtool` based on `runner.os` and the inputs that you pass in.

Note that signing is **not supported** on `linux` because you cannot sign binary files on Linux and it is not required for binaries to be signed anyway.

## Required Inputs

### Signtool

[Signtool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool) is the default `signtool` when using `windows` runners.

These keys must be set correctly on a `windows` runner.

| Name | Description | Example Value |
|---|---|---|
| `file` | The file to sign.  | `bin/test` |
| `certificate-data` | A `base64` encoded string of your `p12` or `pfx` cert contents.| `${{ secrets.APPLE_CERT_DATA }}` |
| `certificate-password` | The password to unlock the `certificate-data`. | `${{ secrets.APPLE_CERT_PASSWORD }}` |

```yaml
jobs:
  sign:
    runs-on: windows-2022
    steps:
      - name: Sign binary
        uses: lando/code-sign-action@v3
        with:
          file: path/to/binary.exe
          certificate-data: ${{ secrets.WINDOZE_CERT_DATA }}
          certificate-password: ${{ secrets.WINDOZE_CERT_PASSWORD }}
```

### Codesign

[Codesign](https://ss64.com/mac/codesign.htmll) is the default (and currently only) `signtool` when using `macos` runners.

These keys must be set correctly on a `macos` runner.

| Name | Description | Example Value |
|---|---|---|
| `file` | The file to sign.  | `bin/test` |
| `certificate-data` | A `base64` encoded string of your `p12` or `pfx` cert contents. | `${{ secrets.APPLE_CERT_DATA }}` |
| `certificate-id \| apple-team-id` | A string to identify the correct signing cert.| `FY8GAUX282` |
| `certificate-password` | The password to unlock the `certificate-data`. | `${{ secrets.APPLE_CERT_PASSWORD }}` |

```yaml
jobs:
  sign:
    runs-on: macos-14
    steps:
      - name: Sign binary
        uses: lando/code-sign-action@v3
        with:
          file: path/to/binary
          certificate-data: ${{ secrets.APPLE_CERT_DATA }}
          certificate-id: FY8GAUX282
          certificate-password: ${{ secrets.APPLE_CERT_PASSWORD }}
```

Note that you can also use `apple-team-id` to set the `certificate-id` if you prefer.

Also note that if you are using an [Apple Developer](https://developer.apple.com/) codesigning certificate **you must** set the `certificate-id` or `apple-team-id` to your [Apple Team ID](https://developer.apple.com/help/account/manage-your-team/locate-your-team-id/)

### Codesign w/ Notarization

You can also `codesign` with basic macOS [notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

These keys must be set correctly on a `macos` runner.

| Name | Description | Example Value |
|---|---|---|
| `file` | The file to sign.  | `bin/test` |
| `certificate-data` | A `base64` encoded string of your `p12` or `pfx` cert contents. | `${{ secrets.APPLE_CERT_DATA }}` |
| `certificate-password` | The password to unlock the `certificate-data`. | `${{ secrets.APPLE_CERT_PASSWORD }}` |
| `apple-notary-user` | The Apple Developer account email to use in notarization. | `${{ secrets.APPLE_NOTARY_USER }}` |
| `apple-notary-password` | The Apple Developer account password to use in notarization. | `${{ secrets.APPLE_NOTARY_PASSWORD }}` |
| `apple-product-id` | The Apple Developer Product ID to use in notarization. | `dev.lando.code-sign-action` |
| `apple-team-id` | The Apple Team ID for the certificate. | `FY8GAUX282` |
| `options` | Additional options to pass into `codesign` | `--options runtime --entitlements entitlements.xml` |

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

Note that it's only possible to `codesign` and `notarize` using an Apple Developer certificate.

Also note that you _probably_ need to set the `options` as above. You can look [here](https://github.com/lando/code-sign-action/blob/main/entitlements.xml) for an example `entitlements.xml` but you will want to configure it to your needs.

### KeyLocker

You can also sign on `windows` runners using [KeyLocker](https://docs.digicert.com/zh/digicert-keylocker.html) by setting the additional `keylocker` inputs as below:

These keys must be set correctly on a `windows` runner.

| Name | Description | Example Value |
|---|---|---|
| `file` | The file to sign.  | `bin/test` |
| `certificate-data` | A `base64` encoded string of your `SM_CLIENT_CERT_FILE`. | `${{ secrets.KEYLOCKER_CLIENT_CERT }}` |
| `certificate-password` | The `SM_CLIENT_CERT_PASSWORD` to unlock the `SM_CLIENT_CERT_FILE`. | `${{ secrets.KEYLOCKER_CLIENT_CERT_PASSWORD }}` |
| `keylocker-host` | The `SM_HOST` of the KeyLocker host eg DigiCert One. | `https://clientauth.one.digicert.com`|
| `keylocker-api-key` | The `SM_API_KEY` for the KeyLocker `SM_HOST`. | `${{ secrets.KEYLOCKER_API_KEY }}` |
| `keylocker-cert-sha1-hash` | The `SM_CODE_SIGNING_CERT_SHA1_HASH` fingerprint for `SM_CLIENT_CERT_FILE`. | `${{ secrets.KEYLOCKER_CERT_SHA1_HASH }}` |
| `keylocker-keypair-alias` | The `SM_KEYPAIR_ALIAS` for the KeyLocker `SM_HOST`. | `${{ secrets.KEYLOCKER_KEYPAIR_ALIAS }}` |

```yaml
jobs:
  sign:
    runs-on: windows-2022
    steps:
      - name: Sign binary
        uses: lando/code-sign-action@v3
        with:
          file: dist/@lando/code-sign-action.exe
          certificate-data: ${{ secrets.KEYLOCKER_CLIENT_CERT }}
          certificate-password: ${{ secrets.KEYLOCKER_CLIENT_CERT_PASSWORD }}
          keylocker-host: https://clientauth.one.digicert.com
          keylocker-api-key: ${{ secrets.KEYLOCKER_API_KEY }}
          keylocker-cert-sha1-hash: ${{ secrets.KEYLOCKER_CERT_SHA1_HASH }}
          keylocker-keypair-alias: ${{ secrets.KEYLOCKER_KEYPAIR_ALIAS }}

```

## Outputs

```yaml
outputs:
  file:
    description: "The path to the signed and/or notarized file."
    value: ${{ steps.code-sign-action.outputs.file }}
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

* [LICENSE](/LICENSE)
* [TERMS OF USE](https://docs.lando.dev/terms)
* [PRIVACY POLICY](https://docs.lando.dev/privacy)
* [CODE OF CONDUCT](https://docs.lando.dev/coc)

