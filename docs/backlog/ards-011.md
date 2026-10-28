# [ARDS-011] ✅ DONE - Document the bootstrap of a host that runs the play on itself

**Status**: Done (2026-10-28)
**Priority**: Low
**Component**: `README.md`
**Related**: [ARDS-010](ards-010.md): installs uv on request and reports a hand-installed copy

**Summary**:
As the operator of a host that provisions itself, I want the README to say what has to be on
the host before the first run, so that I do not wait for the role to install the tool that
Ansible itself comes from.

**Description**:
The README assumes a control node that reaches the host over SSH. A host can also run the
play on itself, with `--connection local`: a WSL distribution, for example, which has no SSH
server. There, Python and Ansible must be in place before the first run. When uv installs
Ansible (`uv tool install ansible-core`), uv comes first, by hand, and the role cannot be what
installs it: a chicken-and-egg problem.

`dev_stack_install_uv: true` then puts a second uv next to the hand-installed one; the copy in
`~/.local/bin` comes first on the PATH, and the role warns about it on every run. The way out
is to leave `dev_stack_install_uv` at `false` on such a host. The README does not say so.

Raised on 2026-10-28.

**Scope Decisions**:
- **Documentation only** (the agent's call): the role already does the right thing with
  `dev_stack_install_uv: false`: it neither installs uv nor looks at `~/.local/bin`. No
  variable and no task changes.

**Acceptance Criteria**:
- [x] The README's requirements name what a host that runs the play on itself needs before
      the first run, and that `dev_stack_install_uv` stays `false` when a hand-installed uv
      provides Ansible
- [x] CI is green after the push
