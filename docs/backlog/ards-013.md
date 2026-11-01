# [ARDS-013] Install Claude Code from Anthropic's apt repository, on request

**Status**: In Progress
**Priority**: Medium
**Component**: `tasks/main.yml`, `defaults/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario
**Related**: [ARDS-007](ards-007.md) — `tea`, the other agent tool on the host;
[ARDS-012](ards-012.md) — `become` drops the proxy variables

**Summary**:
As the operator of a dev host whose coding agent runs on the host, I want the role to install
Claude Code from Anthropic's apt repository, so that the agent is there without a hand install
and a plain `apt upgrade` keeps it current.

**Description**:
The coding agent runs on the host and drives the DevPod workspaces from outside, like `tea`
in ARDS-007. Today a consumer installs Claude Code by hand.

Anthropic publishes a signed apt repository for Claude Code. The setup is the same as the
role's Docker block: a key in `/etc/apt/keyrings/` and a repository that names it in
`signed-by`:

- Key: `https://downloads.claude.ai/keys/claude-code.asc`, fingerprint
  `31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE`
- Repository: `https://downloads.claude.ai/claude-code/apt/<channel>`, suite `<channel>`,
  component `main`, package `claude-code`
- Channels: `stable` serves a version about one week old and skips releases with major
  regressions. `latest` serves every release as soon as it ships. A newly launched model can
  need a version newer than `stable` serves.

Claude Code does not update itself when apt installs it, because an update needs root.
`apt update && apt upgrade` updates it with the rest of the host, and so does the role's own
apt upgrade on a re-run. Claude Code may announce a version before the apt repository has it.

*Proxy.* A consumer behind a proxy typically has it in two places, and not in sudo's
environment. In a WSL distro, wsl-manager (shortcuts) sets it up this way:

- `/etc/profile.d/wsl-manager-proxy.sh` exports `http_proxy`, `https_proxy`, `no_proxy`, their
  uppercase variants and, for TLS inspection, `SSL_CERT_FILE` and `NODE_EXTRA_CA_CERTS`
  pointing at the system trust store. Only the user's shells read it.
- `/etc/apt/apt.conf.d/99proxy` sets `Acquire::http::Proxy` and `Acquire::https::Proxy`, so
  apt reaches the internet as root.

Debian's sudo has `env_reset` and no `env_keep` for the proxy, so `sudo env` shows none of
these variables (checked on such a distro on 2026-11-01). Under `become`, apt therefore works
and `get_url` does not: a key download as root connects directly and fails (ARDS-012). The
user running the role has the variables and can download the key. Claude
Code itself runs as the user, so it takes the proxy and the CA from the user's environment.

Source: [Claude Code setup — Linux package managers](https://code.claude.com/docs/en/setup#install-with-linux-package-managers)

**Scope Decisions**:
- **Off by default.** Not every consumer runs Claude Code; `dev_stack_install_claude_code`
  turns it on.
- **apt only.** No native installer and no npm: the package manager owns the binary, and
  updates go through the host's normal upgrade.
- **Channel as a variable**, `dev_stack_claude_code_channel`, default `stable`, one of
  `stable` or `latest`. Switching it rewrites the repository; the next upgrade follows it.
- **The connecting user downloads the key.** The download runs with `become: false`, so it
  has the user's environment and with it the proxy; a second task copies the file as root
  to `/etc/apt/keyrings/claude-code.asc` (`remote_src`). Then nothing in this block fetches as
  root except apt, which has its own proxy, so the block works behind a proxy without the
  play-level `environment:` of ARDS-012. The role ships no key.
- **curl, not `get_url`.** A TLS-inspecting proxy may re-sign with a CA whose Basic
  Constraints are not marked critical. Python 3.13 and later check X.509 strictly and refuse
  it, and `get_url` runs on the target's Python; a newer Python keeps the check. curl
  verifies the chain without it, once the CA is in the system trust store. A consumer
  playbook already fetches DevPod with curl for the same reason. The block installs `curl`
  with `python3-debian`.
- **No Claude Code settings.** The role writes no `settings.json`, no managed settings and no
  proxy. The proxy and the CA reach Claude Code through the user's environment.
- **amd64 only**, like the Docker repository; following the host architecture is ARDS-004e's
  job.

**Acceptance Criteria**:
- [ ] With `dev_stack_install_claude_code: true`, the connecting user downloads the key
      (`become: false`), the role copies it as root to `/etc/apt/keyrings/claude-code.asc`,
      adds the repository as a deb822 source with `signed_by`, and installs `claude-code`;
      `claude --version` runs as the login user
- [ ] `dev_stack_claude_code_channel` picks the repository URL and suite; `stable` is the
      default, and the argument spec rejects any value other than `stable` or `latest`
- [ ] A re-run changes nothing; with the variable `false` the role touches nothing of Claude
      Code
- [ ] The README lists the option, the channels, that `apt upgrade` updates Claude Code, and
      that behind a proxy apt needs its own proxy setting in `/etc/apt/apt.conf.d/` and the
      user's environment the proxy and CA variables for Claude Code
- [ ] Checked on a WSL distro behind px set up by wsl-manager, through the consumer's
      provisioning playbook: the role installs Claude Code, and `claude` reaches the API as
      the login user
- [ ] The test scenario covers the install
- [ ] CI is green after the push
