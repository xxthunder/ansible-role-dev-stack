# [ARDS-015] Install the build prerequisites of a C/C++ product line on the host, on request

**Status**: In Progress
**Priority**: Medium
**Component**: `tasks/main.yml`, `defaults/main.yml`, `meta/argument_specs.yml`, `README.md`,
test scenario
**Related**: [ARDS-010](ards-010.md) — uv, which the Python step builds on;
[ARDS-014](ards-014.md) — the latest tool installed on request

**Summary**:
As the operator of a dev host, I want the role to install what a CMake/Poetry product line
needs to build on the host itself, outside its dev container, so that I can run that
project's gate on the host the same way its bare-Linux CI job does.

**Description**:
A consuming project, SPLED (a public software product line demo), is developed in its dev
container, where everything is provisioned. Its CI also runs a bare-Linux job, which first
provisions the runner with two scripts of the project:

- as root, apt packages: `libc6-dev`, `build-essential`, `7zip`, `pipx`;
- as the user: uv, CPython 3.11, and Poetry 2.4.1 through pipx. The script also points
  `~/.local/bin/python` at that CPython.

After that, the project's own `build.sh --install` fetches the compilers, CMake and Ninja
itself (through its tool installer), so the host needs nothing more than the list above.

On a dev host set up by this role, none of the apt packages is installed. uv is there, with
CPython 3.14 and 3.15 only, and Poetry is missing. Running the project's scripts by hand would
change the host outside the role, and the second one would also repoint the user's `python`.
The gate therefore runs only in the dev container today. Whether it passes on a bare host is
known only from CI.

The packages exist in Debian 13: `7zip` 25.01, `build-essential` 12.12, `pipx` 1.7.1 (apt
candidates, checked 2026-11-04). Debian's `python3-poetry` is 2.1.2, older than the 2.4.1 the
project pins.

A second product line hit the same gap on 2026-11-11 (SPLE-2784). Its pipeline installs gcc
15.2, clang 20, CMake and Ninja through poks, but on the host neither compiler can link a
program: `ld: cannot find Scrt1.o` and `crti.o`, which `libc6-dev` provides. Its report tests
then fail on the missing `7z`. That product line needs CPython 3.13, not 3.11, so the option
serves more than one version.

**Scope Decisions**:
- **Off by default**, like every other tool installed on request: not every host builds C/C++.
- **Generic, not project-specific.** The option installs the build prerequisites. It knows
  nothing about the project and runs none of its scripts.
- **The user's `python` stays as it is.** The role installs the CPython the option names
  through uv and leaves `~/.local/bin/python` alone. A project picks its interpreter through
  Poetry.
- **No project checkout, no `build.sh` run.** Cloning the project and running its gate stay
  with the operator.
- **Poetry through uv, pinned** (2026-11-11): the role runs `uv tool install poetry==<version>`
  as the login user. uv is already on the host, so Poetry needs no pipx. `pipx` stays in the
  apt list, because the project's scripts call it.
- **A list of CPython versions** (2026-11-11): the option takes a list, so one host serves
  both product lines (3.11 for SPLED, 3.13 for SPLE-2784).
- **The option needs a uv and says so** (2026-11-11): the role uses the uv the login user
  already has — a hand-installed one in `~/.local/bin` first, as the shell's PATH finds it,
  else the role's own in `dev_stack_uv_bin_dir`. With neither there, the run fails early with
  a message that names `dev_stack_install_uv`. The role does not turn on uv by itself. A
  host that runs the play on itself keeps its hand-installed uv (README → Requirements).
- **Poetry reaches the PATH through a link** (2026-11-11): the role links `poetry` from the
  login user's uv tool install into `dev_stack_uv_bin_dir`. It works in every login shell and
  touches no shell configuration.

**Acceptance Criteria**:
- [ ] With the option on, the role installs `libc6-dev`, `build-essential`, `7zip` and `pipx`
      through apt
- [ ] With the option on, the login user has Poetry at the configured version and the
      configured CPython through uv; `poetry --version` runs in a login shell
- [ ] `~/.local/bin/python` is unchanged by a run
- [ ] A re-run changes nothing; with the option off the role touches none of it
- [ ] The README lists the option and its variables
- [ ] The test scenario covers the install
- [ ] On the WSL consumer, with the option on, SPLED's
      `./build.sh --install && ./build.sh --selftests --marker gate_develop_pr` passes on the
      host
