# [ARDS-006] Quiet the notice `podman-docker` prints on every `docker` call

**Status**: Open
**Priority**: Low
**Component**: `tasks/main.yml` (Podman block), test scenario
**Related**: [ARDS-003](ards-003.md)

**Summary**:
As a user of rootless Podman, I want `docker` calls to print only their own output, so that
my terminal and DevPod's logs carry no notice on every call.

**Description**:
The `docker` wrapper from `podman-docker` prints "Emulate Docker CLI using podman. Create
/etc/containers/nodocker to quiet msg." on every call — seen in a WSL distro on
`ssh <workspace>.devpod`. The file `/etc/containers/nodocker` silences it.

**Acceptance Criteria**:
- [ ] With Podman selected, the role creates `/etc/containers/nodocker`
- [ ] The test scenario asserts that `docker --version` prints no emulation notice
