# [ARDS-012] The bootstrap note installs Ansible on a Python it does not support

**Status**: Open
**Priority**: Medium
**Component**: `README.md`
**Related**: [ARDS-011](ards-011.md): added the bootstrap note this item corrects

**Summary**:
As the operator of a host that provisions itself, I want the README's bootstrap command to
install Ansible on a Python it supports, so that the first run does not fail before the role
is even fetched.

**Description**:
The bullet ARDS-011 added to the README's requirements recommends
`uv tool install ansible-core`. uv then takes the newest Python it has. On a host whose uv
already manages Python 3.15, every Ansible command fails at start:

```
AttributeError: module 'dataclasses' has no attribute '_is_type'
```

ansible-core 2.21.5 patches the private `dataclasses._is_type` while it starts up; Python
3.15 no longer has it (3.14.10 still does). ansible-core lists Python 3.12 to 3.14 as
supported, but its `Requires-Python` is only `>=3.12`, so uv sees no conflict.

`uv tool install --python 3.14 ansible-core` works.

Found on a consumer's first run on 2026-10-28.

**Scope Decisions**:
- **Documentation only** (the agent's call): the role runs on the target's system Python and
  is not affected; only the command that installs Ansible on the control node changes.

**Acceptance Criteria**:
- [ ] The README's bootstrap command pins a Python that ansible-core supports, and says why
- [ ] CI is green after the push
