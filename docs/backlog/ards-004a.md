# [ARDS-004a] ✅ DONE - The first run on a fresh host fails: the user manager is not up yet

**Status**: Done (2026-10-02)
**Priority**: High
**Component**: `tasks/main.yml` (persistent ssh-agent block), test scenario

**Summary**:
As a user setting up a fresh host, I want the first run of the role to succeed, so that I do
not have to run it twice.

**Description**:
`loginctl enable-linger` starts `user@<uid>.service` asynchronously. The next task, "Enable
and start the stock ssh-agent socket and service", talks to the user manager under
`/run/user/<uid>` at once. On a host where the user never logged in, that manager is not up
yet and the first real run fails with "Failed to connect to bus"; a second run succeeds.
Every fresh VM and WSL distro hits this, and the bootstrap repo
`xxthunder/xxthunder-workbench-setup` depends on it being fixed.

The test scenario switches the persistent agent off, so CI never reaches this path.

**Investigation (2026-10-02)**:
The suspected race did not reproduce. A second test scenario, `agent`, converges the role
with `dev_stack_ssh_agent: true` for a user that never logged in, in a systemd Debian 13
container — first with `dbus` only, then with `dbus-user-session` and `libpam-systemd` as on
a Debian 13 cloud image, where `systemctl --user` goes through `/run/user/<uid>/bus`. Both
times linger, the user manager and `ssh-agent.socket` came up on the first run, and the
idempotence run reported no change. In practice the case is rarer still: when Ansible
connects as `dev_stack_user`, that SSH login has already started the user manager.

**Scope Decisions**:
- **No fix without a failing test.** The role stays unchanged.
- **The `agent` scenario stays** as CI coverage of the persistent agent on a fresh host,
  which the default scenario switches off. If the race shows up on a real host, that
  scenario is where to reproduce it.

**Acceptance Criteria**:
- [x] A test scenario converges with `dev_stack_ssh_agent: true` for a user that never
      logged in
- [x] It converges on the first run and is idempotent
- [x] The suspected race is reproduced and fixed, or the item records why not
