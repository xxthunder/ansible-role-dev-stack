# dev-stack

Ansible role for the **host software stack of a headless Linux dev host** whose
project toolchains live in [DevPod](https://devpod.sh/) workspaces.

Thin by design: the host is a container host for DevPod. Each project's
toolchain lives in its own `.devcontainer`, not on the host, and this role
installs no coding agent and no toolchain. The host carries only what is needed
to run and reach workspaces, plus the operator's shell and a git identity that
outlives a disconnect.

## What it installs

- **apt full-upgrade**: a cloud image is only patched to its build date.
- **Base packages**: `ca-certificates` and `tmux`. tmux is the host-side session
  multiplexer that keeps long-running sessions alive across disconnects, kept in
  one place rather than baked into every devcontainer.
- **qemu-guest-agent**, only with `dev_stack_qemu_guest_agent: true`: it reports
  the guest IP and heartbeat to a QEMU/Proxmox host and is useless elsewhere.
- **Docker Engine** from Docker's own apt repository, the DevPod container
  runtime. The login user is added to the `docker` group.
- **DevPod CLI**: a single static binary in `/usr/local/bin`.
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

## Role variables

Types and purpose are in [`meta/argument_specs.yml`](meta/argument_specs.yml),
values in [`defaults/main.yml`](defaults/main.yml).

| Variable | Default | Purpose |
| --- | --- | --- |
| `dev_stack_user` | `vmuser` | Login user the stack is installed for. |
| `dev_stack_apt_upgrade` | `true` | Run `apt dist-upgrade` first. |
| `dev_stack_base_packages` | `ca-certificates`, `tmux` | Base packages for every host. |
| `dev_stack_qemu_guest_agent` | `false` | Install and start qemu-guest-agent; set it on a QEMU/Proxmox VM. |
| `dev_stack_install_docker` | `true` | Install Docker Engine and add the user to `docker`. |
| `dev_stack_docker_gpg_url` | Docker's Debian key URL | Docker's apt signing key. |
| `dev_stack_docker_repo_uri` | Docker's Debian repo URI | Docker's apt repository. |
| `dev_stack_docker_packages` | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` | Docker packages. |
| `dev_stack_install_devpod` | `true` | Install the DevPod CLI. |
| `dev_stack_devpod_version` | `latest` | Pin a release tag (e.g. `v0.6.15`) for reproducibility. |
| `dev_stack_devpod_url` | derived from the version | Download URL of the DevPod binary. |
| `dev_stack_devpod_path` | `/usr/local/bin/devpod` | Where the binary goes. |
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
