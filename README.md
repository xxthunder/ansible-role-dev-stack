# Ansible Role: dev-stack

[![CI](https://github.com/xxthunder/ansible-role-dev-stack/actions/workflows/test.yml/badge.svg)](https://github.com/xxthunder/ansible-role-dev-stack/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-blue.svg)](https://docs.ansible.com/)
[![ansible-lint](https://img.shields.io/badge/ansible--lint-passing-brightgreen.svg)](https://ansible.readthedocs.io/projects/lint/)

Ansible role for the **host software stack of a headless Linux dev host** whose
project toolchains live in [DevPod](https://devpod.sh/) workspaces.

Thin by design: the host is a container host for DevPod. Each project's
toolchain lives in its own `.devcontainer`, not on the host, and this role
installs no toolchain, except on request the build prerequisites of a C/C++ product
line (`dev_stack_install_build_prerequisites`), and a coding agent only on request. The host carries only
what is needed to run and reach workspaces, plus the operator's shell and a git
identity that outlives a disconnect.

## What it installs

- **apt full-upgrade**: a cloud image is only patched to its build date.
- **Base packages**: `ca-certificates`, `tmux`, `git-lfs` and `curl`. tmux is the
  host-side session multiplexer that keeps long-running sessions alive across
  disconnects, kept in one place rather than baked into every devcontainer. `git-lfs`
  serves the git that runs on the host — an editor over Remote-SSH, a coding agent.
  Debian's package sets the LFS filters in `/etc/gitconfig` on install, so clones fetch
  LFS content instead of pointer files. curl is what the operator and the
  apt-repository key downloads use. Keep curl when you override
  `dev_stack_base_packages`; the key downloads need it.
- **qemu-guest-agent**, only with `dev_stack_qemu_guest_agent: true`: it reports
  the guest IP and heartbeat to a QEMU/Proxmox host and is useless elsewhere.
- **A container runtime for DevPod**: Docker Engine from Docker's own apt
  repository by default, with the login user in the `docker` group; or rootless
  Podman (see "Container runtime" below).
- **DevPod CLI**: a single static binary in `/usr/local/bin`.
- **tea**, only with `dev_stack_install_tea: true`: the Gitea CLI, for a coding agent that
  runs on the host and opens pull requests on a Gitea forge. A pinned release, verified
  against the SHA-256 file published next to it; Debian's `tea` package is an unrelated
  editor. The login is a token and stays with the operator: `tea login add` once per host.
- **uv**, only with `dev_stack_install_uv: true`: the Python package and project manager,
  for a coding agent on the host that runs its helper scripts with `uv run`; uv fetches
  their interpreter and dependencies itself. A pinned release, verified against the
  SHA-256 file published next to it, unpacked to `/opt/uv/<version>` with `uv` and `uvx`
  linked into `/usr/local/bin`. The default is past the eMudhra/emSign CA incident of
  October 2026 (0.13.4 or later). A uv the user installed by hand into `~/.local/bin`
  shadows the role's; the role warns about it and leaves it in place.
- **gh**, only with `dev_stack_install_gh: true`: the GitHub CLI, for a coding agent that
  runs on the host and opens pull requests on GitHub. It comes from GitHub's signed apt
  repository; `apt upgrade` updates it. The signing key is fetched fresh on every run,
  because GitHub rotated it in 2026. The login stays with the operator: `gh auth login`
  once per host.
- **Build prerequisites**, only with `dev_stack_install_build_prerequisites: true`: what a
  CMake/Poetry product line needs to build on the host itself, outside its dev container.
  The apt packages in `dev_stack_build_packages`, the CPython versions in
  `dev_stack_build_pythons` and a pinned Poetry (`dev_stack_poetry_version`), the last two
  installed for the login user through uv. It needs a uv: the user's own in
  `~/.local/bin`, else the role's (`dev_stack_install_uv: true`); with neither the role
  stops before it installs anything. The user's `python` stays as it is: uv installs the
  CPythons without `--default`, so it puts versioned links (`python3.13`, ...) into
  `~/.local/bin` and leaves `python` alone. A `~/.local/bin/poetry` that pipx installed
  earlier makes `uv tool install` fail ("executable already exists"): run
  `pipx uninstall poetry` first.
  `poetry` is linked into `dev_stack_uv_bin_dir`. uv runs as the login user, so the role
  hands it the connecting user's proxy and CA variables (`HTTP_PROXY`, `HTTPS_PROXY`,
  `NO_PROXY`, their lower-case forms, `SSL_CERT_FILE`, `SSL_CERT_DIR`, those that are set).
  The role checks out no project.
- **Claude Code**, only with `dev_stack_install_claude_code: true`: the coding agent, for
  one that runs on the host. It comes from Anthropic's signed apt repository, channel
  `stable` by default or `latest`. `apt upgrade` updates it; it never updates itself. The
  role writes no Claude Code settings.
- **Shell**: `zsh` and `oh-my-zsh` for the operator, with zsh as the login
  shell. zsh is load-bearing, not just preference: it sources `~/.zshenv` on
  every invocation, including the non-interactive `zsh -c` that sshd runs for
  `ssh <host> <cmd>`, which is how a client's `devpod ssh --stdio` proxy reaches
  a workspace. That is where the agent fallback below hooks in.
- **Persistent ssh-agent for a forge-only git identity** (see below).
- **Key-only SSH**: password and keyboard-interactive logins are disabled with an
  `/etc/ssh/sshd_config.d/` drop-in, reloaded rather than restarted, so a bad
  config fails the reload instead of dropping the daemon.

Out of scope: a host firewall (the role targets a single-owner host reached
key-only, typically over a private network or VPN), VPN clients, and everything
inside the devcontainers.

## Container runtime

`dev_stack_container_runtime` picks one of three:

| Value | What the role does |
| --- | --- |
| `docker` (default) | Docker Engine from Docker's apt repository; the user joins the `docker` group |
| `podman` | rootless Podman: removes the Docker packages, installs `podman`, `podman-docker`, `slirp4netns` and `uidmap`, quiets `podman-docker`'s notice with `/etc/containers/nodocker`, makes `/` a shared mount at boot, enables linger and the user's `podman.socket`, and exports `DOCKER_HOST` in `~/.profile` and `~/.zprofile` |
| `none` | no container runtime |

Why it is set up this way:

- **Docker is the default** because the devcontainer ecosystem is Docker-first:
  features such as docker-in-docker and socket mounting are built and tested
  against Docker, and DevPod's best-travelled driver is the `docker` one.
- **Podman runs rootless**, with no daemon and no root-owned socket. That is the
  point of choosing it; a rootful Podman would buy nothing over Docker.
- **DevPod finds Podman through `podman-docker`**, which provides a `docker`
  command. DevPod's default `docker` provider, and every other tool that calls
  `docker`, work unchanged; nothing per user under `~/.devpod` is configured.
- **The two never coexist on one host**: both answer to `docker` and
  `DOCKER_HOST`, so choosing Podman removes the Docker packages.
- **`/` is a shared mount**, which rootless Podman expects. systemd makes it one
  on a normal host; where `/` comes up private, as on WSL or in a container,
  the unit `dev-stack-shared-root.service` runs `mount --make-rshared /` at
  every boot.

On WSL the distribution needs `systemd=true` in `/etc/wsl.conf`. Whoever
creates the distribution sets that; this role does not touch `wsl.conf`.

The Podman path is tested on Debian 13 and Ubuntu 24.04. The rest of the role
targets Debian 13 for now.

## The two-identity credential model

Git and everything else use different keys with different blast radius:

| Key | Lives | Reaches |
| --- | --- | --- |
| forge-only key | on the host, in a persistent user ssh-agent | your git forge (GitHub, Gitea, …), nothing else |
| your personal key | on your own machine | your other servers; forwarded with `ssh -A` only while you are attached |

On Debian 13 / OpenSSH 10 the persistent agent is the OS's own socket-activated
unit (`ssh-agent.socket` + `ssh-agent.service` in `/usr/lib/systemd/user`). The
role does not ship a competing unit, because a same-named one collides with the
stock socket and hangs. It extends the stock service with a drop-in that loads
the forge key and starts it eagerly at boot, and enables `linger` so it runs
headless across reboots.

`~/.zshenv` selects that agent **only when the session's own agent does not
answer**. Liveness, not existence: a collapsed forwarding tunnel leaves the
socket file behind, so testing for the file tests a corpse. Only `ssh-add -l`
exit 2 (cannot reach) counts as dead; exit 1 is an agent that answered and holds
no keys yet. **Which identity a session gets is decided on the client**: connect
without agent forwarding and you get the forge agent, which outlives your laptop,
so tmux sessions, `devpod ssh` and the workspaces below them keep working after
you detach. Connect with `ssh -A` and your personal key is used, untouched.
Nothing here re-points a shared path, so two sessions with different intents
cannot steal each other's agent.

The role converges the agent to hold **exactly** the forge key. A long-lived
agent otherwise accumulates whatever gets `ssh-add`ed into it, and once a
personal key is resident every detached session silently has access the model
forbids. Pruning only ever touches the host's own agent: the task pins
`SSH_AUTH_SOCK` to the persistent socket, never a forwarded one.

**The private key is delivered out-of-band, never by this role.** Copy it to the
host first, for example
`scp ~/.ssh/id_ed25519_forge user@host:~/.ssh/ && ssh user@host chmod 600 ~/.ssh/id_ed25519_forge`,
then run the play; the agent picks it up and tolerates its absence. Its public
key goes on your git forge only, never into any server's `authorized_keys`.

## Requirements

- Runs on the target with `become: true` and `gather_facts: true` (the Docker
  repo's suite comes from `ansible_facts['distribution_release']`).
- Debian 13 (trixie) on **amd64**; ansible-core ≥ 2.15 for `deb822_repository`.
  The Docker repository and the DevPod download are amd64-only for now.
- With `dev_stack_ssh_agent: true` the role **owns `~/.zshenv`** of
  `dev_stack_user` and replaces an existing one. Keep your own settings in
  `~/.zshrc`, which the role only seeds once and never overwrites.
- **A host that runs the play on itself** (`--connection local`, for example a WSL
  distribution without an SSH server) needs Python and Ansible before the first run, so the
  role cannot install the tool they come from. If uv provides Ansible there
  (`uv tool install ansible-core`), install uv by hand first and leave
  `dev_stack_install_uv` at `false`: the role then neither installs a second uv nor warns
  about yours.

## Role variables

Types and purpose are in [`meta/argument_specs.yml`](meta/argument_specs.yml),
values in [`defaults/main.yml`](defaults/main.yml).

| Variable | Default | Purpose |
| --- | --- | --- |
| `dev_stack_user` | `vmuser` | Login user the stack is installed for. |
| `dev_stack_apt_upgrade` | `true` | Run `apt dist-upgrade` first. |
| `dev_stack_base_packages` | `ca-certificates`, `tmux`, `git-lfs`, `curl` | Base packages for every host. Keep `curl` when you override it. |
| `dev_stack_qemu_guest_agent` | `false` | Install and start qemu-guest-agent; set it on a QEMU/Proxmox VM. |
| `dev_stack_container_runtime` | `docker` | `docker`, `podman` (rootless) or `none`; see "Container runtime". |
| `dev_stack_install_docker` | `true` | Deprecated: `false` means runtime `none`. |
| `dev_stack_docker_gpg_url` | Docker's Debian key URL | Docker's apt signing key. |
| `dev_stack_docker_repo_uri` | Docker's Debian repo URI | Docker's apt repository. |
| `dev_stack_docker_packages` | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` | Docker packages. |
| `dev_stack_podman_packages` | `podman`, `podman-docker`, `slirp4netns`, `uidmap` | Packages for the `podman` runtime. |
| `dev_stack_install_devpod` | `true` | Install the DevPod CLI. |
| `dev_stack_devpod_version` | `latest` | Pin a release tag (e.g. `v0.6.15`) for reproducibility. |
| `dev_stack_devpod_url` | derived from the version | Download URL of the DevPod binary. |
| `dev_stack_devpod_path` | `/usr/local/bin/devpod` | Where the binary goes. |
| `dev_stack_install_tea` | `false` | Install tea, the Gitea CLI. |
| `dev_stack_tea_version` | `0.16.0` | tea release; bumping it re-fetches the binary. |
| `dev_stack_tea_url` | derived from the version | Download URL; its SHA-256 file sits next to it. |
| `dev_stack_tea_path` | `/usr/local/bin/tea` | Where the binary goes. |
| `dev_stack_install_uv` | `false` | Install uv and uvx. |
| `dev_stack_uv_version` | `0.13.6` | uv release; bumping it installs the new release next to the old one and moves the links. |
| `dev_stack_uv_url` | derived from the version | Download URL; its SHA-256 file sits next to it. |
| `dev_stack_uv_home` | `/opt/uv` | Releases unpack to `<home>/<version>`. |
| `dev_stack_uv_bin_dir` | `/usr/local/bin` | Where the `uv` and `uvx` links go. |
| `dev_stack_install_claude_code` | `false` | Install Claude Code from Anthropic's apt repository. |
| `dev_stack_claude_code_channel` | `stable` | `stable` or `latest`; the apt suite of the repository. |
| `dev_stack_claude_code_gpg_url` | Anthropic's key URL | Anthropic's apt signing key. |
| `dev_stack_claude_code_repo_uri` | derived from the channel | Anthropic's apt repository for the channel. |
| `dev_stack_install_gh` | `false` | Install gh from GitHub's apt repository. |
| `dev_stack_gh_gpg_url` | GitHub's key URL | GitHub's apt signing key. |
| `dev_stack_gh_repo_uri` | `https://cli.github.com/packages` | GitHub's apt repository for gh. |
| `dev_stack_install_build_prerequisites` | `false` | Install the build prerequisites of a C/C++ product line; needs a uv. |
| `dev_stack_build_packages` | `libc6-dev`, `build-essential`, `7zip`, `pipx` | apt packages the build prerequisites install. |
| `dev_stack_build_pythons` | `["3.13"]` | CPython versions uv installs for the user. |
| `dev_stack_poetry_version` | `2.4.1` | Poetry release installed for the user; bumping it installs the new one. |
| `dev_stack_install_zsh` | `true` | Install zsh and oh-my-zsh. |
| `dev_stack_set_user_shell` | `true` | Make zsh the login shell (needed for the `~/.zshenv` hook). |
| `dev_stack_ohmyzsh_repo` | the oh-my-zsh GitHub URL | Where oh-my-zsh is cloned from. |
| `dev_stack_ssh_agent` | `true` | Set up the persistent forge-only ssh-agent. |
| `dev_stack_ssh_agent_key` | `.ssh/id_ed25519_forge` | Forge-only private key, relative to the user's home. |
| `dev_stack_ssh_agent_sock` | `openssh_agent` | OpenSSH's own socket name; change only with reason. |
| `dev_stack_disable_password_auth` | `true` | Key-only SSH via an `sshd_config.d` drop-in. |

**DevPod version:** with `latest`, a re-run does not upgrade an installed binary
(`get_url` skips when the file exists). Bump `dev_stack_devpod_version` and
re-run to upgrade.

**Claude Code and gh behind a proxy:** the role downloads each signing key with curl as the
connecting user, so that user's proxy variables apply. curl, not `get_url`: Python 3.13
and later refuse a TLS-inspecting proxy's CA whose Basic Constraints are not marked
critical, and curl accepts it once the CA is in the system trust store. apt fetches as
root and needs its own proxy setting in `/etc/apt/apt.conf.d/` (`Acquire::http::Proxy`
and `Acquire::https::Proxy`). This holds for both apt repositories, Anthropic's and
GitHub's. Claude Code and gh run as the user and take their proxy from the user's
environment: set `HTTPS_PROXY`/`https_proxy` and `NO_PROXY`. Claude Code also needs
`NODE_EXTRA_CA_CERTS` where TLS inspection replaces certificates; gh, a Go program, uses
the system trust store.

## Example playbook

Installed from Galaxy, the role is `xxthunder.dev_stack`; as a git checkout or
submodule it takes its directory name, as here:

```yaml
- name: Install the dev stack
  hosts: devhosts
  gather_facts: true
  become: true
  roles:
    - role: dev-stack
      vars:
        dev_stack_user: me
        dev_stack_ssh_agent_key: ".ssh/id_ed25519_forge"
```

**`--check` caveat:** on a fresh host the Docker step cannot be fully previewed:
the apt repository is added only in the preview, so `docker-ce` has nothing to
resolve against. Apply once; later `--check` runs are exact.

## Testing

- `molecule test` converges the role in a systemd-enabled Debian 13 container,
  checks idempotence and verifies the result. Docker and the persistent agent are
  off in that scenario.
- `tests/test_agent_selection.sh` and `tests/test_agent_convergence.sh` exercise
  the agent logic against real `ssh-agent` processes; they need `zsh` and
  `ssh-agent`, nothing else. `tests/test_role_hygiene.sh` checks that the role
  leaves files it does not own alone.

GitHub Actions runs ansible-lint, the shell tests and Molecule on every push and
pull request.

## License

MIT
