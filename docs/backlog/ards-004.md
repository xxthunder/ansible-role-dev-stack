# [ARDS-004] Harden the role: findings from its first review

**Status**: In Progress
**Priority**: High
**Component**: `tasks/main.yml`, `templates/zshenv.j2`, `defaults/main.yml`, test scenario
**Related**: [ARDS-002](ards-002.md) — the review of its release found these

**Summary**:
As a user of the role on a fresh host, I want the behaviour the first review questioned
fixed, so that the role works on its first run and on hosts unlike the one it came from.

**Description**:
All of these behaved the same on the original host; [ARDS-002](ards-002.md) kept behaviour
unchanged on purpose. Each fix changes what runs, so each needs a failing test first.

**Substories**:
- [x] [ARDS-004a](ards-004a.md) — the first run on a fresh host fails: the user manager is not up yet
- [ ] [ARDS-004b](ards-004b.md) — a mistyped `dev_stack_user` is created instead of failing
- [ ] [ARDS-004c](ards-004c.md) — a hanging agent socket blocks every zsh
- [ ] [ARDS-004d](ards-004d.md) — the role replaces an existing `~/.zshenv`
- [ ] [ARDS-004e](ards-004e.md) — downloads: amd64 only, no checksum for DevPod
- [ ] [ARDS-004f](ards-004f.md) — `--check` is not exact on a provisioned host
- [ ] [ARDS-004g](ards-004g.md) — `become_user` needs `acl` when connecting as another user

**Acceptance Criteria**:
- [ ] All substories are Done
- [ ] A release is tagged
