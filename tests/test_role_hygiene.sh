#!/usr/bin/env bash
# Checks on what the role must never do to files it does not own.
#
#   ./tests/test_role_hygiene.sh
set -uo pipefail

TASKS="$(dirname "$0")/../tasks/main.yml"
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
local_bin=$(grep -c '\.local/bin/' "$TASKS")
local_bin_stat=$(grep -B1 '\.local/bin/' "$TASKS" | grep -c 'ansible\.builtin\.stat:')
check "H2: no task but a stat names a path in the user's ~/.local/bin" \
  "$((local_bin - local_bin_stat))" "0"

# The Claude Code signing key is fetched as the connecting user: `become` drops
# the user's proxy variables (sudo env_reset), so a root fetch cannot reach the
# download host. Look within that one task only, from its "- name:" line to the
# next one at the same indent.
key_task=$(awk '/^ +- name:/ { if (found) exit; buf="" } { buf = buf $0 "\n" }
  /\{\{ dev_stack_claude_code_gpg_url \}\}/ { found=1 }
  END { if (found) printf "%s", buf }' "$TASKS")
check "H3: the Claude Code key download runs as the connecting user" \
  "$(printf '%s' "$key_task" | grep -c 'become: false')" "1"

# Python 3.13+ checks X.509 strictly and refuses a TLS-inspecting proxy's CA
# whose Basic Constraints are not marked critical; get_url runs on that Python.
# curl verifies the chain without that check, so the key comes with curl.
check "H4: the Claude Code key download uses curl, not get_url" \
  "$(printf '%s' "$key_task" | grep -c 'ansible\.builtin\.get_url:') $(printf '%s' "$key_task" | grep -c -- '- curl$')" "0 1"

echo
if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; fi
exit "$fails"
