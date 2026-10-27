# [ARDS-010] Install uv, at a version past the emSign CA incident

**Status**: In Progress
**Priority**: High
**Component**: `defaults/main.yml`, `tasks/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario, `tests/test_role_hygiene.sh`
**Related**: [ARDS-007](ards-007.md): the same reasoning as for `tea`, a tool the host-side
agent uses belongs on the host

**Summary**:
As the operator of a dev host, I want the role to install uv at a pinned version past the
emSign CA incident, so that Python helper scripts run with `uv run` on the host use a trusted
CA bundle and the version does not depend on a manual install.

**Description**:
Agent tooling on the host runs Python helper scripts with `uv run`, so uv is expected on
every dev host. The role does not install it; on the consumer's host it was installed by
hand into the user's `~/.local/bin` and was at 0.12.4 on 2026-10-27.

The Python Software Foundation's advisory on the eMudhra/emSign CA incident (about
2026-10-20) asks for uv 0.13.4 or later: the emSign root is removed from the CA bundles, and
older tools keep trusting it. uv publishes, per release, an archive holding `uv` and `uvx`
with a SHA-256 file next to it.

The consumer turns it on with `dev_stack_install_uv: true` and removes the hand-installed
copy itself.

Raised on 2026-10-27.

**Scope Decisions**:
- **A pinned version, like `tea`.** A version variable with a URL built from it, so an update
  is a change to the defaults, and the consumer can pin another version.
- **On request, like `tea`** (the agent's call): `dev_stack_install_uv` defaults to `false`.
  The role is thin by design, and uv serves a coding agent on the host, which not every
  consumer runs.
- **One directory per release, linked into the PATH** (the agent's call): the archive is
  verified against its SHA-256 file and unpacked to `/opt/uv/<version>`; `uv` and `uvx` in
  `/usr/local/bin` are links to it. A bumped version installs next to the old one and moves
  the links, and a re-run with the same version changes nothing. Old releases stay on disk.
- **A hand-installed uv is reported, not removed** (the agent's call, 2026-10-27): uv's own
  installer puts it into `~/.local/bin`, ahead of `/usr/local/bin` on the PATH. That file is
  the user's, and the role does not touch files it does not own (`tests/test_role_hygiene.sh`),
  so it warns and leaves the copy in place. This replaces the criterion that the
  hand-installed copy no longer shadows the role's.

**Acceptance Criteria**:
- [ ] The role installs uv at a pinned version, 0.13.4 or later, on the default path for all
      users
- [ ] The default test scenario asserts that `uv --version` reports the pinned version
- [ ] The README and the defaults name the new variables; `meta/argument_specs.yml` keeps no
      values
- [ ] A uv the user installed by hand into `~/.local/bin` is reported, and no task but a
      `stat` touches that directory
- [ ] CI is green on the pull request
- [ ] Released as a release candidate for the consumer to verify on a real host
