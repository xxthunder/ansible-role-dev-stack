# [ARDS-004d] The role replaces an existing `~/.zshenv`

**Status**: Open
**Priority**: Low
**Component**: `tasks/main.yml`, `templates/zshenv.j2`, `README.md`

**Summary**:
As a user with my own `~/.zshenv`, I want the role to add its agent fallback without
deleting my settings.

**Description**:
The managed `~/.zshenv` is written with the template's default `force`, so an existing file
is replaced. The README says so. A gentler way — a managed file that `~/.zshenv` sources, or
a marked block — is a design decision.

**Acceptance Criteria**:
- [ ] Decided and recorded in the README; if changed, a test shows an existing `~/.zshenv`
      line survives a run
