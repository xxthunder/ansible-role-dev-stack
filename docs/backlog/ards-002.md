# [ARDS-002] ✅ DONE - Initial public release

**Status**: Done (2026-10-02)
**Priority**: High
**Component**: the whole role; `.github/workflows/test.yml`; `molecule/default/`; `tests/`
**Related**: HSH-086a in the first consuming project — it swaps its inline copy of the role
for this repo as a submodule and verifies the release on its dev VM

**Summary**:
As a maintainer of a headless DevPod dev host, I want the dev-stack role as a public,
tested repository, so that any host — a dev VM, a WSL distro, a colleague's machine — can
use it without the project it came from.

**Description**:
The role was written inside a private infrastructure project for one dev VM. This item
publishes it with its behaviour unchanged for that host, except where publishing requires a
change:

- Defaults and comments that named the original host or project are neutral. The
  forge-only key defaults to `.ssh/id_ed25519_forge`; consumers set their own.
- `qemu-guest-agent` was installed and started on every host and fails outside a QEMU VM.
  `dev_stack_qemu_guest_agent` (default `false`) now gates it.

The first review of the release found three defects that change nothing on the existing
host, fixed here with a test that failed first:

- The agent convergence reported no change even when it pruned or loaded keys: its
  `changed_when` read stdout, but `ssh-add` writes to stderr. The snippet prints its own
  marker on stdout.
- A forge key that cannot be fingerprinted left an empty fingerprint, which counted every
  loaded key as the forge key, so a foreign key was never pruned. It now fails.
- A migration task from the private history deleted a user's own
  `~/.config/systemd/user/ssh-agent.service`. Removed.

The remaining findings of that review change behaviour and are [ARDS-004](ards-004.md).

**Scope Decisions**:
- **Fresh history** — the repository starts from a clean commit, not from the private
  project's history.
- **Same shape as the maintainer's other public roles**: MIT licence, README documenting
  every variable, `meta/argument_specs.yml`, ansible-lint and yamllint configs, a Molecule
  scenario in a systemd Debian 13 container, GitHub CI.
- **Docker and the persistent agent are off in the Molecule scenario** — dockerd inside that
  container and a lingering systemd user instance are not what the role meets on a real
  host. The shell tests cover the agent logic; the consumer's check run covers Docker.
- **Release candidate first**: `v1.0.0-rc1`, verified by the consumer, then `v1.0.0` at the
  same commit.

**Acceptance Criteria**:
- [x] The repository is public and carries no private details of the consuming project
- [x] CI on `main` is green: ansible-lint, the shell tests, Molecule with idempotence
- [x] `v1.0.0-rc1` is tagged
- [x] The consumer's check run on its dev VM shows no unexpected change (HSH-086a)
- [x] `v1.0.0` is tagged at the same commit
