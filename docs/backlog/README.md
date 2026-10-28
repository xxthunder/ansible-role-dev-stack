# Backlog

## Status Legend

- **Open** - Ready to be picked up
- **In Progress** - Currently being worked on
- **Done** - Completed

## Table of Contents

### Open
- [ARDS-011 — Document the bootstrap of a host that runs the play on itself](ards-011.md)
- [ARDS-005 — Ubuntu 24.04 support](ards-005.md)
- [ARDS-004h — The Docker path fails on a minimal host: `deb822_repository` needs `python3-debian`](ards-004h.md)
- [ARDS-004g — `become_user` needs `acl` when connecting as another user](ards-004g.md)
- [ARDS-004f — `--check` is not exact on a provisioned host](ards-004f.md)
- [ARDS-004e — Downloads: amd64 only, no checksum for DevPod](ards-004e.md)
- [ARDS-004d — The role replaces an existing `~/.zshenv`](ards-004d.md)
- [ARDS-004c — A hanging agent socket blocks every zsh](ards-004c.md)
- [ARDS-004b — A mistyped `dev_stack_user` is created instead of failing](ards-004b.md)

### In Progress
- [ARDS-004 — Harden the role: findings from its first review](ards-004.md)
- [ARDS-001 — Backlog refinement](ards-001.md)

### Done
- [ARDS-010 — Install uv, at a version past the emSign CA incident](ards-010.md)
- [ARDS-009 — Install `git-lfs` with the base packages](ards-009.md)
- [ARDS-008 — CI runs on a Python that ansible-core supports](ards-008.md)
- [ARDS-007 — Install `tea`, the Gitea CLI, on request](ards-007.md)
- [ARDS-006 — Quiet the notice `podman-docker` prints on every `docker` call](ards-006.md)
- [ARDS-004a — The first run on a fresh host fails: the user manager is not up yet](ards-004a.md)
- [ARDS-003 — Podman as an alternative runtime, rootless](ards-003.md)
- [ARDS-002 — Initial public release](ards-002.md)

---

## Notes

- **ID prefix**: `ARDS` (ansible-role-dev-stack)
- This repository is public: no host names, addresses or private details of any consumer.
  A bare item ID of a consuming project (e.g. `HSH-086a`) is fine; links into it are not.
- Keep items actionable with clear acceptance criteria
- Do NOT list commit hashes in backlog entries — the backlog is part of the commit itself,
  so hashes are circular and go stale after squash/rebase
