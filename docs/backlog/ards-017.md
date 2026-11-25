# [ARDS-017] Install `wget` with the base packages

**Status**: Open
**Priority**: High
**Component**: `defaults/main.yml`, `README.md`, test scenario
**Related**: [ARDS-009](ards-009.md): the same reasoning for `git-lfs`, a tool that VS Code
Remote-SSH needs on the host

**Summary**:
As the operator of a dev host I reach with VS Code Remote-SSH, I want the role to install
`wget`, so that VS Code can install and update its server on the host without a package
installed by hand.

**Description**:
On 2026-11-25, `code .` on a dev host set up by the role failed while VS Code updated its
server (version `8a14f0cc1b08d531eb83255ea3764ae22aa932b5`):

```
Updating VS Code Server to version 8a14f0cc1b08d531eb83255ea3764ae22aa932b5
Removing previous installation...
ERROR: Failed to download the VS Code server. 'wget' not installed.
Please install wget:
Debian/Ubuntu: sudo apt-get install wget
```

The role installs `curl`, but not `wget`. The server installer of this VS Code version asks
for `wget` by name and does not fall back to `curl`. The previous server was already
removed when the download failed, so the host has no working VS Code server until `wget`
is installed. Whether older VS Code versions used `curl` was not checked.

**Scope Decisions**:
- **A base package, on by default.** `wget` joins `dev_stack_base_packages`, like
  `git-lfs` in ARDS-009: it is small, and the editor over Remote-SSH is a main use of the
  host. A consumer who overrides the list leaves it out by doing so.

**Acceptance Criteria**:
- [ ] `dev_stack_base_packages` defaults to `ca-certificates`, `tmux`, `git-lfs`, `curl`,
      `wget`
- [ ] The default test scenario asserts that `wget --version` runs
- [ ] The README and the comment in `defaults/main.yml` name the new default and why;
      `meta/argument_specs.yml` keeps no values
- [ ] CI is green on the pull request
- [ ] Released as a release candidate for the consumer to verify on a real host
