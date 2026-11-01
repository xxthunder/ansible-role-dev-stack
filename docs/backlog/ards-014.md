# [ARDS-014] Install `gh`, the GitHub CLI, from GitHub's apt repository, on request

**Status**: Open
**Priority**: Medium
**Component**: `tasks/main.yml`, `defaults/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario
**Related**: [ARDS-007](ards-007.md) — `tea`, the forge CLI for Gitea;
[ARDS-013](ards-013.md) — Claude Code from an apt repository, the pattern this follows;
[ARDS-012](ards-012.md) — `become` drops the proxy variables

**Summary**:
As the operator of a dev host whose coding agent runs on the host and works with a GitHub
forge, I want the role to install `gh`, so that the agent can open pull requests there without
a tool set up by hand.

**Description**:
The coding agent runs on the host and drives the DevPod workspaces from outside. For a Gitea
forge the role installs `tea` (ARDS-007); for GitHub it installs nothing, so the agent cannot
open a pull request. A consumer installed `gh` by hand on 2026-11-01 to unblock ARDS-013.

GitHub publishes a signed apt repository for `gh`:

- Key: `https://cli.github.com/packages/githubcli-archive-keyring.gpg`, a binary keyring
- Repository: `https://cli.github.com/packages`, suite `stable`, component `main`, package `gh`
- Source: [cli/cli — Installing gh on Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

*The keyring holds two keys.* `2C6106201985B60E6C7AC87323F3D4EA75716059` expired on
2026-09-05; `7F38BBB59D064DBCB3D84D725612B36462313325`, created 2026-04-07, is valid. GitHub's
install page lists both fingerprints. apt accepts the repository with this keyring (checked on
2026-11-01): a keyring downloaded before the rotation would fail with an expired key, so the
role downloads the key fresh rather than shipping it.

*The hand install* used the paths the role should use, so that the role takes it over without
a second source for the same repository:

- `/etc/apt/keyrings/githubcli-archive-keyring.gpg` (root, 0644)
- `/etc/apt/sources.list.d/github-cli.sources`, deb822, `Architectures: amd64`,
  `Signed-By` the keyring above — what `deb822_repository` with `name: github-cli` writes

*Proxy.* As in ARDS-013: the key download runs as the connecting user, because `become` drops
the user's proxy variables; apt fetches as root with its own proxy setting; `gh` runs as the
user and takes `HTTPS_PROXY` from the user's environment.

**Scope Decisions**:
- **Off by default.** Not every consumer uses GitHub; `dev_stack_install_gh` turns it on.
- **apt, the same block shape as ARDS-013.** Key downloaded as the connecting user
  (`become: false`) into a temp file and copied as root; `python3-debian` installed before
  `deb822_repository`; `check_mode: false` on the temp-file steps.
- **No login.** `gh auth login` is a credential: the operator runs it once per host, the role
  does not — as with `tea login add`.
- **amd64 only**, like the other repositories; following the host architecture is ARDS-004e's
  job.

**Acceptance Criteria**:
- [ ] With `dev_stack_install_gh: true`, the role installs the keyring to
      `/etc/apt/keyrings/githubcli-archive-keyring.gpg`, the deb822 source `github-cli`, and
      the package `gh`; `gh --version` runs as the login user
- [ ] On a host where `gh` was installed by hand with these paths, a run reports no second
      source and changes at most the files' content
- [ ] A re-run changes nothing; with the variable `false` the role touches nothing of `gh`
- [ ] The README lists the option and that `gh auth login` stays with the operator
- [ ] The test scenario covers the install
- [ ] CI is green after the push
