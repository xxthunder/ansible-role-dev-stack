# [ARDS-005] Ubuntu 24.04 support

**Status**: Open
**Priority**: Medium
**Component**: `defaults/main.yml`, `tasks/main.yml`, `meta/main.yml`, test scenarios
**Related**: the WSL tooling recommends Ubuntu 24.04 for WSL distros; the bootstrap repo
`xxthunder/xxthunder-workbench-setup` needs the role there for its Ubuntu profile

**Summary**:
As a user of an Ubuntu 24.04 host or WSL distro, I want the role to work there, so that the
same role sets up Debian and Ubuntu hosts.

**Description**:
The role targets Debian 13. On Ubuntu 24.04 three parts break:

- **Docker** — the repository is fixed to `download.docker.com/linux/debian`; Ubuntu needs
  `download.docker.com/linux/ubuntu` for its suite (`noble`).
- **Key-only sshd** — on Ubuntu 24.04 sshd is socket-activated, so `/run/sshd` does not exist
  until a connection arrives, and the `sshd -t` validation of the hardening drop-in fails
  with "Missing privilege separation directory: /run/sshd".
- **Persistent agent** — Ubuntu 24.04's `openssh-client` ships only an `ssh-agent.service`
  for graphical sessions and **no `ssh-agent.socket`**. The role enables and extends exactly
  that stock socket (Debian 13 / OpenSSH 10), so the agent block fails.

The Podman path ([ARDS-003](ards-003.md)) is tested on Ubuntu 24.04 already.

**Open Questions**:
- The agent on Ubuntu: ship the role's own socket unit there, or switch the persistent
  agent off on hosts without the stock socket?

**Acceptance Criteria**:
- [ ] Every test scenario also runs on Ubuntu 24.04 and passes
- [ ] The Docker repository follows the distribution
- [ ] The persistent agent works on Ubuntu 24.04, or the role refuses it with a clear message
- [ ] `meta/main.yml` lists Ubuntu noble; a release is tagged
