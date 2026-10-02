# [ARDS-004e] Downloads: amd64 only, no checksum for DevPod

**Status**: Open
**Priority**: Low
**Component**: `tasks/main.yml`, `defaults/main.yml`

**Summary**:
As a user of an arm64 host, I want Docker and DevPod for my architecture, verified, so that
the role works there and installs nothing unchecked as root.

**Description**:
The Docker repository's `architectures` and the DevPod URL are fixed to amd64; they should
follow `ansible_facts['architecture']`. The DevPod binary comes from `latest` without a
checksum and lands in `/usr/local/bin` as root.

**Acceptance Criteria**:
- [ ] Architecture taken from the facts, with a test for the mapping
- [ ] DevPod verified by checksum, or the decision not to recorded in the README
