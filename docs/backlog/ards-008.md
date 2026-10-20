# [ARDS-008] CI runs on a Python that ansible-core supports

**Status**: In Progress
**Priority**: High
**Component**: `.github/workflows/test.yml`
**Related**: [ARDS-007](ards-007.md) — its pull request found this

**Summary**:
As the role maintainer, I want CI to fail only when the role is wrong, so that a red run on a
pull request means something.

**Description**:
Both Python jobs ask `actions/setup-python` for `python-version: "3.x"`. On 2026-10-20 that
resolved to Python 3.15.0, which ansible-core 2.21.5 does not support ("supports Python up to
3.14"). ansible-lint and Molecule then crash on import with `AttributeError: module 'dataclasses'
has no attribute '_is_type'`, before a single scenario runs — on every push, `main` included.

**Scope Decisions**:
- **Pin the minor version** to the newest one ansible-core supports, `3.14`, in both jobs.
  Moving it on is a deliberate change when ansible-core supports the next one.

**Acceptance Criteria**:
- [ ] Both Python jobs in `.github/workflows/test.yml` use Python 3.14
- [ ] ansible-lint and Molecule run to their own result on a pull request
