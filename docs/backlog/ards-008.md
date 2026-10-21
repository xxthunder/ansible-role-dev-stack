# [ARDS-008] ✅ DONE - CI runs on a Python that ansible-core supports

**Status**: Done (2026-10-20)
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

Once it ran, the same runs carried two more notices: `actions/checkout@v4` and
`actions/setup-python@v5` target the deprecated Node 20 and are forced onto Node 24, and the
runner's pip announces its own upgrades.

**Scope Decisions**:
- **Pin the minor version** to the newest one ansible-core supports, `3.14`, in both jobs.
  Moving it on is a deliberate change when ansible-core supports the next one.
- **The actions move to v7**, the first majors that run on Node 24; pip's version check is
  switched off for the workflow.
- **Left as they are:** the notice that `ubuntu-latest` moves to Ubuntu 26 (the scenarios run
  in Debian and Ubuntu containers), the `master` hint from inside `actions/checkout`, and
  Molecule's notes about steps without a playbook.

**Acceptance Criteria**:
- [x] Both Python jobs in `.github/workflows/test.yml` use Python 3.14
- [x] ansible-lint and Molecule run to their own result on a pull request
- [x] No Node 20 deprecation and no pip upgrade notice in the run
