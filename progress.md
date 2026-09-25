# progress.md

## Goal / scope

Compute half of the Home Affairs demo module pair: a RHEL 9 EC2 with secure defaults and
optional Vault SSH CA trust. No Ansible knowledge — that lives in `terraform-aap-postdeploy`.

## Done

- v1.0.0: instance, optional security group, t-shirt sizing, Vault SSH CA `user_data`.
- 11 tests passing on `mock_provider`; `terraform validate` and `tflint` clean.
- GitHub Actions running fmt / validate / tflint / test on PR.

## Next

- Publish to the `djoo-hashicorp` private module registry.
- Consume from the Demo 1 root alongside `terraform-aap-postdeploy`.

## Key context

- **Placement is an input.** `vpc_id` / `subnet_id` are passed in, never discovered, so the
  same module serves a remote-state-backed root and a data-source-backed self-service root.
- **tflint config is the organisation's**, copied from `terraform-agentic-workflows`. It
  requires `Environment`, `Application` and `ManagedBy` tags — hence the `application` and
  `managed_by` variables.
- Provider constraints use `>=` per the module standard, not `~>`.
