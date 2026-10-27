# [ARDS-010] Install uv, at a version past the emSign CA incident

**Status**: Open
**Priority**: High
**Component**: `defaults/main.yml`, `tasks/`, `README.md`, test scenario
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
older tools keep trusting it. uv publishes a standalone binary per release.

Raised on 2026-10-27.

**Scope Decisions**:
- **A pinned version, like `tea`.** A version variable with a URL built from it, so an update
  is a change to the defaults, and the consumer can pin another version.

**Acceptance Criteria**:
- [ ] The role installs uv at a pinned version, 0.13.4 or later, on the default path for all
      users
- [ ] The default test scenario asserts that `uv --version` reports the pinned version
- [ ] The README and the defaults name the new variables; `meta/argument_specs.yml` keeps no
      values
- [ ] A uv the user installed by hand earlier no longer shadows the role's
