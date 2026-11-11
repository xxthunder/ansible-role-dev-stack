#!/usr/bin/env bash
# Checks on what the role must never do to files it does not own.
#
#   ./tests/test_role_hygiene.sh
set -uo pipefail

TASKS="$(dirname "$0")/../tasks/main.yml"
APT_REPO="$(dirname "$0")/../tasks/apt_repo.yml"
BUILD="$(dirname "$0")/../tasks/build_prerequisites.yml"
fails=0

check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then echo "  ok   - $name"
  else echo "  FAIL - $name"; echo "         want: $want"; echo "         got:  $got"
       fails=$((fails + 1)); fi
}

echo "== role hygiene =="

# The role extends the stock ssh-agent.service with a drop-in. A user's own
# ~/.config/systemd/user/ssh-agent.service is theirs: never delete it.
check "H1: no task touches the user's own ssh-agent.service" \
  "$(grep -c '\.config/systemd/user/ssh-agent\.service"' "$TASKS")" "0"

# A uv the user installed into ~/.local/bin shadows the role's. It is theirs:
# the role reports it, never removes it. The only task naming the path stats it.
# Comment lines are not tasks.
local_bin=$(cat "$TASKS" "$BUILD" | grep -v '^ *#' | grep -c '\.local/bin/')
local_bin_stat=$(cat "$TASKS" "$BUILD" | grep -v '^ *#' | grep -B1 '\.local/bin/' | grep -c 'ansible\.builtin\.stat:')
check "H2: no task but a stat names a path in the user's ~/.local/bin (main.yml, build_prerequisites.yml)" \
  "$((local_bin - local_bin_stat))" "0"

# An apt repository's signing key is fetched as the connecting user: `become` drops
# the user's proxy variables (sudo env_reset), so a root fetch cannot reach the
# download host. Look within that one task only, from its "- name:" line to the
# next one at the same indent.
key_task=$(awk '/^ +- name:/ { if (found) exit; buf="" } { buf = buf $0 "\n" }
  /\{\{ dev_stack_apt_repo_key_url \}\}/ { found=1 }
  END { if (found) printf "%s", buf }' "$APT_REPO" 2>/dev/null)
check "H3: the apt-repository key download runs as the connecting user" \
  "$(printf '%s' "$key_task" | grep -c 'become: false')" "1"

# Python 3.13+ checks X.509 strictly and refuses a TLS-inspecting proxy's CA
# whose Basic Constraints are not marked critical; get_url runs on that Python.
# curl verifies the chain without that check, so the key comes with curl.
check "H4: the apt-repository key download uses curl, not get_url" \
  "$(printf '%s' "$key_task" | grep -c 'ansible\.builtin\.get_url:') $(printf '%s' "$key_task" | grep -c -- '- curl$')" "0 1"

# uv runs as the login user, so `become` drops the connecting user's proxy and CA
# variables. One `become: false` task reads them into dev_stack_connecting_env, and
# every task that runs uv passes them on through `environment:`. At least one uv run
# must exist, or the two counts of zero would pass on a file that does nothing.
uv_runs=$(grep -c '{{ dev_stack_build_uv }}' "$BUILD" 2>/dev/null)
env_lines=$(grep -c 'environment: "{{ dev_stack_connecting_env }}"' "$BUILD" 2>/dev/null)
check "H5: every uv run carries the connecting user's proxy variables" \
  "$([ "$uv_runs" -gt 0 ] && [ "$uv_runs" = "$env_lines" ] && echo paired || echo "uv runs=$uv_runs, environment lines=$env_lines")" "paired"
# The task that reads the environment is the one whose registered result the
# set_fact of dev_stack_connecting_env reads. Task boundary: any "- name:" line,
# at any indent (build_prerequisites.yml has them at column 0).
env_reg=$(awk '/^ *- name:/ { buf="" } { buf = buf $0 "\n" }
  /dev_stack_connecting_env:/ { found=1 }
  found && match($0, /[a-z_0-9]+\.stdout_lines/) { print substr($0, RSTART, RLENGTH - 13); exit }' "$BUILD" 2>/dev/null)
read_task=$(awk -v reg="$env_reg" '/^ *- name:/ { if (found) exit; buf="" } { buf = buf $0 "\n" }
  reg != "" && $0 ~ "register: " reg "$" { found=1 }
  END { if (found) printf "%s", buf }' "$BUILD" 2>/dev/null)
check "H5: the task that reads the environment for dev_stack_connecting_env runs become: false" \
  "$(printf '%s' "$read_task" | grep -c 'become: false')" "1"

echo
if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; fi
exit "$fails"
