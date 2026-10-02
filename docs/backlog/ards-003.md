# [ARDS-003] Podman as an alternative runtime, rootless

**Status**: Open
**Priority**: Medium
**Component**: `tasks/main.yml`, `defaults/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario
**Related**: the WSL tooling that sets up rootless Podman today (`wsl-manager` in
`xxthunder/shortcuts`, `lib/wsl/scripts/install-podman.sh`); the bootstrap repo
`xxthunder/xxthunder-workbench-setup` uses this role for WSL distros

**Summary**:
As a user of a WSL distro or a host without Docker, I want the role to install rootless
Podman instead of Docker, so that DevPod runs there the same way.

**Description**:
The role installs Docker Engine only. A WSL distro is set up with rootless Podman today, by
a shell script. Docker stays the default, so existing hosts do not change.

Rootless Podman, the way the WSL tooling does it:

- remove the Docker packages (the two runtimes exclude each other)
- install `podman`, `slirp4netns` and `uidmap`
- enable linger for the user and the user `podman.socket`
- export `DOCKER_HOST=unix:///run/user/<uid>/podman/podman.sock`, so DevPod's `docker`
  driver talks to Podman

On WSL, `systemd=true` and the boot command `mount --make-rshared /` in `/etc/wsl.conf` are
prerequisites. They belong to whoever creates the distro, not to this role.

**Scope Decisions**:
- **Docker stays the default.** A host that sets nothing converges as before.
- **The role stays Linux-only** and knows nothing about WSL.

**Open Questions**:
- How is the runtime chosen — one variable (`dev_stack_container_runtime: docker|podman`) or
  two switches?
- Where is the runtime choice recorded — an ADR in this repository?

**Acceptance Criteria**:
- [ ] With Podman selected, DevPod builds and runs a workspace in a WSL distro
- [ ] A host with the defaults converges without changes
- [ ] The test scenario covers the Podman path
- [ ] A minor release is tagged
