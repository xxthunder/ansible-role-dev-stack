# [ARDS-004g] `become_user` needs `acl` when connecting as another user

**Status**: Open
**Priority**: Low
**Component**: `tasks/main.yml`, `README.md`

**Summary**:
As a user whose Ansible connects as a non-root account other than `dev_stack_user`, I want
the tasks that switch to that user to work.

**Description**:
Switching from one unprivileged user to another needs `acl` on the target or pipelining. The
role does not install `acl`, and the test scenario connects as root, so this path is untested.

**Acceptance Criteria**:
- [ ] `acl` installed by the role, or the requirement recorded in the README
