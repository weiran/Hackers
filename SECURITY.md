# Security Policy

## Supported versions

Security fixes are generally made against the current `master` branch and the latest
App Store release. Older releases may not receive fixes.

## Reporting a vulnerability

Please do not disclose security vulnerabilities in a public issue or pull request.
Report them privately to the repository maintainer through the contact information
listed on the project's GitHub profile, or use GitHub's private vulnerability
reporting feature if it is enabled for this repository.

Include:

* A description and impact assessment.
* Reproduction steps or a proof of concept.
* Affected version, commit, or configuration.
* Any suggested mitigation.

Please allow time for investigation before public disclosure. Do not include real
account credentials, private cookies, signing keys, API keys, or personal data in a
report.

## Secrets and local configuration

Never commit `.env`, App Store Connect credentials, match passwords, provisioning
profiles, private keys, or extracted authentication cookies. If a secret is exposed,
revoke or rotate it immediately and notify the maintainers privately.
