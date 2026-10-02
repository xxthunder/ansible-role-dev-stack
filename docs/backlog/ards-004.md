# [ARDS-004] Harden the role: findings from its first review

**Status**: Open
**Priority**: High
**Component**: `tasks/main.yml`, `templates/zshenv.j2`, `defaults/main.yml`, test scenario
**Related**: [ARDS-002](ards-002.md) — the review of its release found these

**Summary**:
As a user of the role on a fresh host, I want the behaviour the first review questioned
fixed, so that the role works on its first run and on hosts unlike the one it came from.

**Description**:
All of these behaved the same on the original host; [ARDS-002](ards-002.md) kept behaviour
unchanged on purpose. Each fix changes what runs, so each needs a failing test first — in
the test scenario or the shell tests.

1. **Linger race on a fresh host** — `loginctl enable-linger` starts the user manager
   asynchronously; the next task talks to `/run/user/<uid>/bus` at once. On a host where the
   user never logged in, the first real run fails with "Failed to connect to bus" and needs
   a re-run. Every fresh VM and WSL distro hits this; the bootstrap repo
   `xxthunder/xxthunder-workbench-setup` depends on it being fixed.
2. **A missing user is created** — with `dev_stack_install_docker`, the `user` task that adds
   the user to `docker` runs before the `getent` lookup and creates a mistyped user, in a
   root-equivalent group. It should fail fast.
3. **`ssh-add -l` without a timeout in `~/.zshenv`** — a socket that accepts and never
   answers blocks every zsh, including the `devpod ssh --stdio` proxy.
4. **`~/.zshenv` is replaced** — documented in the README; a gentler way (a sourced managed
   file, or a marked block) is a design decision.
5. **amd64 only** — the Docker repository architecture and the DevPod URL are fixed to amd64;
   take them from `ansible_facts['architecture']`.
6. **`ignore_errors` in check mode covers the whole Docker block** — it hides real errors in
   `--check`, not only the expected unresolvable package on a fresh host.
7. **No checksum for the DevPod download** — a binary from `latest`, installed as root.
8. **`become_user` without `acl`** — untested when Ansible connects as a non-root user other
   than `dev_stack_user`.

**Acceptance Criteria**:
- [ ] Finding 1 fixed with a test that failed first; a first run on a fresh host succeeds
- [ ] Findings 2 and 3 fixed with tests that failed first
- [ ] Findings 4 to 8 each fixed or recorded as a decision in the README
- [ ] A release is tagged
