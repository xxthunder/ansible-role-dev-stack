# [ARDS-004b] A mistyped `dev_stack_user` is created instead of failing

**Status**: Open
**Priority**: Medium
**Component**: `tasks/main.yml` (Docker block, account facts)

**Summary**:
As a user of the role, I want a `dev_stack_user` that does not exist to stop the run, so that
a typo does not create an account in the root-equivalent `docker` group.

**Description**:
With `dev_stack_install_docker`, the task that adds the user to `docker` runs before the
`getent` lookup. `ansible.builtin.user` with `groups` and `append` creates a missing user.
The lookup should come first and fail fast.

**Acceptance Criteria**:
- [ ] A test with an unknown `dev_stack_user` fails before any change, and failed to fail
      before the fix
- [ ] No task creates the user
