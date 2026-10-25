# [ARDS-009] ✅ DONE - Install `git-lfs` with the base packages

**Status**: Done (2026-10-25)
**Priority**: Medium
**Component**: `defaults/main.yml`, `README.md`, test scenario
**Related**: [ARDS-007](ards-007.md) — the same reasoning for `tea`: a tool the host-side
agent and editor use belongs on the host; consumer item HSH-093

**Summary**:
As the operator of a dev host I reach with VS Code Remote-SSH, I want the role to install
`git-lfs`, so that the editor's git tooling and repositories that use LFS work on the host
without a package installed by hand.

**Description**:
The role installs `git` (with the shell), but not `git-lfs`. VS Code's git extensions run
on the host when the editor connects over SSH, and Git Graph reports the missing `lfs`
command there. A clone of a repository with LFS objects on such a host checks out pointer
files instead of the content.

Debian 13 ships `git-lfs` in main (3.6.1); it depends on `git`.

**Scope Decisions**:
- **A base package, on by default.** `git-lfs` joins `dev_stack_base_packages`; it is small,
  and git on a dev host is expected to handle LFS. A consumer who overrides the list leaves
  it out by doing so.
- **The package sets the filters.** Debian's `git-lfs` postinst runs
  `git lfs install --skip-repo --system`, so every user's clones fetch LFS content; the role
  adds no task of its own, and the test holds the package to it.

**Acceptance Criteria**:
- [x] `dev_stack_base_packages` defaults to `ca-certificates`, `tmux`, `git-lfs`
- [x] The default test scenario asserts that `git-lfs version` runs and `/etc/gitconfig`
      sets the LFS filter
- [x] The README and the defaults name the new default; `meta/argument_specs.yml` keeps
      no values
- [x] CI is green on the pull request
- [x] Released as a release candidate for the consumer to verify on a real host
