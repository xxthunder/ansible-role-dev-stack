# [ARDS-003] ✅ DONE - Podman as an alternative runtime, rootless

**Status**: Done (2026-10-02)
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

On WSL, `systemd=true` in `/etc/wsl.conf` is a prerequisite and belongs to whoever creates
the distro. The WSL tooling also sets the boot command `mount --make-rshared /` there; the
role makes `/` shared itself (Scope Decisions).

**Scope Decisions**:
- **Docker stays the default.** A host that sets nothing converges as before.
- **The role stays Linux-only** and knows nothing about WSL.
- **One variable** chooses the runtime: `dev_stack_container_runtime` — `docker` (default),
  `podman` or `none` (maintainer, 2026-10-02).
- **`dev_stack_install_docker` stays as a deprecated alias**, so this is a minor release,
  v1.1.0 (maintainer, 2026-10-02): `false` means runtime `none`.
- **DevPod finds Podman through `podman-docker`**, which provides a `docker` command, so the
  default `docker` provider and every other tool that calls `docker` work unchanged
  (maintainer, 2026-10-02).
- **The role makes `/` a shared mount**, which rootless Podman expects: a unit runs
  `mount --make-rshared /` at every boot. systemd already does that on a normal host; where
  `/` comes up private — WSL, containers — the unit makes the difference. The role still
  detects no WSL and leaves `wsl.conf` alone; `systemd=true` stays with whoever creates the
  distribution (maintainer, 2026-10-02).
- **Tested on Debian 13 and Ubuntu 24.04**; the rest of the role on Ubuntu is
  [ARDS-005](ards-005.md).
- **The reasoning goes into a "Container runtime" section of the README**, not an ADR: why
  Docker is the default, why Podman runs rootless, why the two exclude each other. The
  README is where someone choosing a runtime reads; an ADR would duplicate it.

**Acceptance Criteria**:
- [x] With Podman selected, DevPod builds and runs a workspace in a WSL distro
- [x] A host with the defaults converges without changes
- [x] The test scenario covers the Podman path
- [x] With Podman selected, `/` is a shared mount, at every boot
- [x] The README has a "Container runtime" section with the reasoning
- [x] v1.1.0 is tagged
