# [ARDS-007] Install `tea`, the Gitea CLI, on request

**Status**: In Progress
**Priority**: Medium
**Component**: `tasks/main.yml`, `defaults/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario
**Related**: [ARDS-004e](ards-004e.md) — the DevPod download has no checksum; this one has

**Summary**:
As the operator of a dev host whose agent runs on the host and works with a Gitea forge, I want
the role to install `tea`, so that the agent can open pull requests there without a tool set up
by hand.

**Description**:
The role's defaults call it thin by design: project toolchains live in the devcontainers, not on
the host. A forge CLI is no project toolchain, though. The coding agent runs on the host and
drives the DevPod workspaces from outside, so the tool it uses to talk to the forge has to be on
the host too. For a Gitea forge that is `tea`; today a consumer would install it by hand.

`tea` is a single static binary. Its releases are published on `dl.gitea.com` together with a
SHA-256 file for each binary. Debian's own `tea` package is an unrelated text editor, so apt is
not an option.

**Scope Decisions**:
- **Off by default.** Not every consumer uses a Gitea forge; `dev_stack_install_tea` turns it on.
- **A pinned version, verified by checksum.** The version defaults to a release tag rather than
  `latest`, so the download URL and its checksum file follow from it, and `get_url` re-fetches
  the binary when a bumped version changes the checksum.
- **amd64 only**, like DevPod; following the host architecture is ARDS-004e's job for every
  download.
- **No login.** The token is a credential and stays out of the role; `tea login add` remains a
  step the operator runs once per host.

**Acceptance Criteria**:
- [x] With `dev_stack_install_tea: true`, the role installs the pinned `tea` release to
      `/usr/local/bin/tea`, verified against its published SHA-256
- [x] The default test scenario installs it and asserts that `tea --version` runs
- [x] The variables are in `defaults/main.yml`, `meta/argument_specs.yml` and the README
- [x] CI is green on the pull request
- [ ] Released as a release candidate for the consumer to verify on a real host
