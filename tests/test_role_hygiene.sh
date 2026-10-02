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

echo
if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; fi
exit "$fails"
