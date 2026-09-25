# Changelog

All notable changes to this module are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is
[semantic](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-09-25

### Fixed

- **Security: the default AMI lookup no longer uses Red Hat's public account.** It now uses
  the HashiCorp approved base images (`hc-base-rhel-9*-x86_64-*`, owner `888995627335`),
  whose images carry the Uptycs EDR agent required by **HC-COMPUTE-011**. Building from
  Red Hat's public RHEL 9 produces an instance with no EDR and is flagged by security.
  `pkr-RHEL9-SOE` made the same correction in commit `a40e12a`.

### Added

- `ami_owner` and `ami_name_filter` so the base image source is explicit and overridable.
- Test asserting the lookup defaults to the approved account (23 unit tests total).

## [1.2.0] - 2026-09-25

### Fixed

- `user_data` now runs `loginctl enable-linger` for `ansible_user`. Without it, rootless
  containers started by automation are killed when the SSH session that started them closes:
  the playbook reports success and the service is gone moments later. Found while rehearsing
  Demo 1 Part A, where an httpd container started cleanly and then answered nothing.

### Added

- Test asserting `enable-linger` is present in `user_data` (22 unit tests total).

## [1.1.0] - 2026-09-25

### Added

- Integration tests in `tests-integration/` (`apply` mode) asserting the instance reaches
  `running`, a public IP is assigned, the restricted SSH rule is really created, and the
  AMI lookup resolves a real image.
- Unit test coverage for `Large` sizing, explicit `ami_id` override, absence of `user_data`
  when no CA key is supplied, supplied security groups, private placement, IAM instance
  profile, custom root volume size, custom `ansible_user`, and required tag presence.
- CI now validates every directory under `examples/`.

### Changed

- Test files renamed to the `*_unit_test.tftest.hcl` convention.
- Unit tests grew from 11 to 21.

## [1.0.0] - 2026-09-25

### Added

- RHEL 9 EC2 instance with an optional dedicated security group.
- T-shirt sizing (`Small` / `Medium` / `Large`) resolved to `t3.micro` / `t3.small` / `t3.medium`.
- Optional Vault SSH CA trust installed via `user_data`, so automation connects with
  short-lived signed certificates rather than a key stored on the host.
- Secure defaults: encrypted `gp3` root volume, IMDSv2 required, SSH restricted to a
  narrow CIDR rather than the internet.
- AMI looked up from Red Hat's public account when `ami_id` is not supplied.
- 11 tests covering defaults, sizing, tag merging, conditional security group,
  and rejection of invalid inputs.
