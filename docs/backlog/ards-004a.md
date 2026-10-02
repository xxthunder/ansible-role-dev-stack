# [ARDS-004a] The first run on a fresh host fails: the user manager is not up yet

**Status**: In Progress
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

**Acceptance Criteria**:
- [ ] A test scenario converges with `dev_stack_ssh_agent: true` for a user that never
      logged in, and failed before the fix
- [ ] After the fix it converges on the first run and is idempotent
- [ ] A host where the user manager already runs converges without a change
