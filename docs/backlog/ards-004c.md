# [ARDS-004c] A hanging agent socket blocks every zsh

**Status**: Open
**Priority**: Medium
**Component**: `templates/zshenv.j2`, `tests/test_agent_selection.sh`

**Summary**:
As a user of the host, I want a shell even when an agent socket hangs, so that I can still
log in and fix it.

**Description**:
`~/.zshenv` runs `ssh-add -l` without a timeout on every zsh start. A socket that accepts
and never answers blocks every login, tmux pane and `devpod ssh --stdio` proxy. A timeout
has to count as "dead" like exit 2.

**Acceptance Criteria**:
- [ ] A shell test with a socket that accepts and never answers fails before the fix and
      passes after it: the persistent agent is selected within a bounded time
- [ ] The existing selection tests still pass
