# AGENTS.md

## Closed loop

- **Gate**: `scripts/gate`. It runs `lint`, `shell` and `molecule`, and exits 0 only when
  every check is green. CI calls the same script.
- **Where it runs**: on the host. This repository has no dev container.
- **Behind a TLS-inspecting proxy**: run `scripts/gate lint shell` locally. Molecule cannot
  pull from inside its containers there, so require Molecule green in CI before the merge.
- **Rubric**: `docs/rubric.md`. The loop adds its own general rubric next to it.
