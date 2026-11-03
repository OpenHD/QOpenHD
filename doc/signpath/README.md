# Windows signing

The existing `build_windows_installer.yml` workflow accepts `signing_mode`
(`none`, `test`, or `release`) on manual runs. Push and pull request builds
remain unsigned. Signed builds must run in `OpenHD/QOpenHD` and build the
workflow's own commit; no external source revision is accepted.

SignPath must approve QOpenHD as a separate project in the OpenHD OSS
organization, with GitHub Actions origin verification for `OpenHD/QOpenHD`.
Do not reuse the main OpenHD project's repository origin for QOpenHD.
Import both XML configurations in this directory into that project.

Repository variables:

- `SIGNPATH_ORGANIZATION_ID`: OpenHD OSS organization ID
- `SIGNPATH_PROJECT_SLUG`: the approved QOpenHD project slug
- `SIGNPATH_TEST_SIGNING_POLICY_SLUG`: its test policy
- `SIGNPATH_RELEASE_SIGNING_POLICY_SLUG`: its production policy
- `SIGNPATH_TEST_CERTIFICATE_BASE64`: public DER test certificate, base64 encoded

The organization secret `SIGNPATH_API_TOKEN` must be accessible to this
repository, and its CI user must be a submitter on the selected policy.
Never store the token in a variable, source file, or workflow input.

The workflow generates the NSIS uninstaller without installing the application.
It signs and verifies `QOpenHD.exe` and `QOpenHD-Uninstall.exe`, embeds both
in the installer, then signs and verifies the outer installer. Every signature
must be timestamped. The test certificate is trusted only inside the ephemeral
GitHub-hosted test runner; production verification uses normal Windows trust.
Third-party libraries are redistributed unchanged.

Output names distinguish `-Unsigned`, `-Test-Signed`, and `-Signed` builds.
Missing configuration or failed signing stops the job. Test builds are for
onboarding only and must not be distributed as publicly trusted releases.

Complete test signing before requesting SignPath's technical review and
production certificate activation. The OpenHD main project's onboarding must
be completed before additional ecosystem projects can be enabled by SignPath.
