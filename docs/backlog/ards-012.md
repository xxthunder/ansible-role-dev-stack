# [ARDS-012] The README misses two traps of a first run: Python 3.15 and a proxy under sudo

**Status**: Open
**Priority**: Medium
**Component**: `README.md`
**Related**: [ARDS-011](ards-011.md): added the bootstrap note this item corrects

**Summary**:
As the operator of a host that provisions itself, possibly behind a proxy, I want the README
to install Ansible on a Python it supports and to say how the proxy reaches the role's
downloads, so that the first run does not fail on either.

**Description**:
Both traps came up on a consumer's first run on 2026-10-28.

*Python 3.15.* The bullet ARDS-011 added to the README's requirements recommends
`uv tool install ansible-core`. uv then takes the newest Python it has. On a host whose uv
already manages Python 3.15, every Ansible command fails at start:

```
AttributeError: module 'dataclasses' has no attribute '_is_type'
```

ansible-core 2.21.5 patches the private `dataclasses._is_type` while it starts up; Python
3.15 no longer has it (3.14.10 still does). ansible-core lists Python 3.12 to 3.14 as
supported, but its `Requires-Python` is only `>=3.12`, so uv sees no conflict.
`uv tool install --python 3.14 ansible-core` works.

*A proxy under sudo.* Behind a proxy that the firewall enforces, the DevPod download fails:

```
Request failed: <urlopen error [Errno 111] Connection refused>
```

The role runs with `become: true`. Debian's sudo has `env_reset`, which drops `http_proxy`,
`https_proxy` and `no_proxy`, so `get_url` connects directly and the firewall refuses it. apt
is not affected when it has its own proxy setting in `/etc/apt/apt.conf.d/`. The same holds
for every task that fetches over the network: the DevPod, tea and uv downloads and the
oh-my-zsh clone. A play-level `environment:` that hands the variables on works, because
Ansible applies it after `become`:

```yaml
environment:
  http_proxy: "{{ lookup('ansible.builtin.env', 'http_proxy') }}"
  https_proxy: "{{ lookup('ansible.builtin.env', 'https_proxy') }}"
  no_proxy: "{{ lookup('ansible.builtin.env', 'no_proxy') }}"
```

**Scope Decisions**:
- **Documentation only** (the agent's call): the role runs on the target's system Python and
  is not affected by the first trap. The proxy belongs to the play, not the role: the role
  sets no proxy anywhere and stays out of the host's sudo and network setup, so the README
  shows the play-level `environment:` instead of the role taking proxy variables.

**Acceptance Criteria**:
- [ ] The README's bootstrap command pins a Python that ansible-core supports, and says why
- [ ] The README says that `become` drops the proxy variables and shows the play-level
      `environment:` that hands them on
- [ ] CI is green after the push
