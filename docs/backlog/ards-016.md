# [ARDS-016] Install ubc, the ubCode CLI, from useblocks' download server, on request

**Status**: In Progress
**Priority**: Medium
**Component**: `tasks/main.yml`, `defaults/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario
**Related**: [ARDS-007](ards-007.md): `tea`, the download pattern this follows;
[ARDS-004e](ards-004e.md): downloads are amd64 only; [ARDS-012](ards-012.md): `get_url`
without a checksum connects on every run, and `become` drops the proxy variables;
[ARDS-013](ards-013.md): downloads behind a TLS-inspecting proxy

**Summary**:
As the operator of a dev host that checks sphinx-needs projects, I want the role to install
`ubc`, the ubCode command line, in a pinned version, so that `ubc check` runs in any shell on
the host and not only in a VS Code terminal.

**Description**:
`ubc` is the command line of useblocks' ubCode: it checks, queries and builds sphinx-needs
projects (`ubc check`, `ubc build`). Today it reaches a host only inside the ubCode VS Code
extension, at `<extensions>/useblocks.ubcode-<version>-linux-x64/server/cli/ubc`. The
extension's setting `ubcode.cli.terminalIntegration` puts it on the `PATH` of VS Code's
integrated terminals, but not of a plain shell or a coding agent on the host. A consumer
needed `ubc` 0.40.0 in a shell on 2026-11-24 and had only the extension's 0.39.0.

useblocks publishes the binary at a fixed URL, the one their CI action `useblocks/ubc-action`
uses:

```
https://download.useblocks.com/ubc/<version>/ubc-linux-x64-<version>
```

Checked on 2026-11-25 for 0.40.0:

- The binary answers `200`.
- No checksum file is published next to it: `.sha256`, `.sha256sum` and `.sha256.txt` answer
  `403`. So the role cannot verify the download from the server, as it does for `tea`.
- There is no `latest` path (`/ubc/latest/ubc-linux-x64-latest` answers `403`). The version
  must be pinned.

*Licence.* ubCode is free for open-source projects. `ubc` checks the licence when it runs, not
when it is installed; since 0.40.0 the open-source check also works in git worktrees. The role
installs no licence key: a key is a credential, like `tea login add` (ARDS-007).

*Prior art.* useblocks' installation page (0.40.0) publishes one versioned URL per platform,
with no checksum, no signature and no install location. Their CI action `useblocks/ubc-action`
downloads with `curl` without verification, and decides whether to download by comparing
`ubc --version` with the requested version.

**Scope Decisions**:
- **No checksum; the installed version decides** (author, 2026-11-25): useblocks publishes no
  checksum, and its own `ubc-action` verifies none. The role follows that action: it reads
  `ubc --version` and downloads only when the version differs from `dev_stack_ubc_version`. A
  run without a change makes no connection.
- **`curl` as the connecting user, copied as root** (author, 2026-11-25): `become` drops the
  proxy variables (ARDS-012), and `get_url` fails behind a TLS-inspecting proxy (ARDS-013).
  The apt key download in `tasks/apt_repo.yml` is the pattern.
- **`/usr/local/bin/ubc`** (author, 2026-11-25): like `tea`, DevPod and uv, so every user and
  agent on the host finds it. A `ubc` in the dev user's `~/.local/bin` shadows it; the role
  reports that copy and leaves it alone, as it does for uv.
- **Off by default** (the agent's call): not every consumer works with sphinx-needs;
  `dev_stack_install_ubc` turns it on.
- **A pinned version** (forced by the server): `dev_stack_ubc_version`, without a leading `v`,
  because the server has no `latest`.
- **No licence key** (the agent's call): see the description.
- **amd64 only**, like the other downloads; following the host architecture is ARDS-004e's
  job.
- **The consumer switch stays out**: setting `dev_stack_install_ubc: true` is a change in the
  consuming repository, after this item ships.

**Acceptance Criteria**:
- [ ] With `dev_stack_install_ubc: true`, the role installs `ubc` in the version
      `dev_stack_ubc_version` to `/usr/local/bin/ubc` (mode 0755), and `ubc --version` prints
      that version
- [ ] Bumping `dev_stack_ubc_version` replaces the binary on the next run; a run without a
      change reports no change
- [ ] The download is verified against a SHA-256, or the item records why it is not
- [ ] With the default, the role installs no `ubc`
- [ ] The defaults, `meta/argument_specs.yml` and the README describe the variables
- [ ] CI is green after the push
