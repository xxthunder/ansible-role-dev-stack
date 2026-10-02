# [ARDS-004h] The Docker path fails on a minimal host: `deb822_repository` needs `python3-debian`

**Status**: Open
**Priority**: Medium
**Component**: `tasks/main.yml` (Docker block), test scenario

**Summary**:
As a user installing Docker on a minimal host, I want the role to add the Docker apt repository
without a module dependency I have to install first.

**Description**:
`ansible.builtin.deb822_repository` needs `python3-debian` on the target and does not install
it by default. The Debian 13 cloud image brings it in as a dependency of `reportbug`, so
the original host had it; minimal images do not. On the Debian 13 and Ubuntu 24.04 test
images the task fails with "python3-debian is not installed, and install_python_debian is
False". No scenario runs the Docker path — all of them set
`dev_stack_install_docker: false` — so CI never saw it. Found by the red run of
[ARDS-003](ards-003.md).

**Acceptance Criteria**:
- [ ] A scenario converges the Docker path on a minimal Debian 13 host
- [ ] The role installs `python3-debian` before adding the repository (or sets
      `install_python_debian`)
