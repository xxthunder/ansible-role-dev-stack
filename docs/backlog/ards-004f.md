# [ARDS-004f] `--check` is not exact on a provisioned host

**Status**: Open
**Priority**: Low
**Component**: `tasks/main.yml` (Docker block)

**Summary**:
As a user previewing a run, I want `--check` on a provisioned host to show only real changes
and real errors, as the README promises.

**Description**:
- `ignore_errors: "{{ ansible_check_mode }}"` covers the whole Docker block, so a wrong
  key URL or package name passes a dry run silently; only the expected unresolvable
  package on a fresh host should be tolerated.
- "Add the Docker apt signing key" (`get_url`) reports `changed` under `--check` although
  the key on disk is identical to the download.

**Acceptance Criteria**:
- [ ] A check run on a provisioned host reports no change for an identical key
- [ ] A wrong package name fails the check run on a provisioned host
