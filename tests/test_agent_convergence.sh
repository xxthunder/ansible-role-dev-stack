#!/usr/bin/env bash
# Unit test for the agent-convergence snippet in tasks/main.yml.
#
# The snippet is extracted verbatim from the task between its marker comments,
# so this cannot drift from what Ansible actually runs. Pruning is destructive,
# which is why it is tested here rather than only on the host.
#
#   ./tests/test_agent_convergence.sh
set -uo pipefail

TASKS="$(dirname "$0")/../tasks/main.yml"
fails=0

WORK="$(mktemp -d)"
trap 'pkill -f "ssh-agent -a $WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

# Extract the snippet, strip the task's YAML indent, render the two Jinja vars.
sed -n '/--- agent-convergence begin/,/--- agent-convergence end/p' "$TASKS" \
  | sed 's/^        //' \
  | sed "s|{{ dev_stack_user_home }}/{{ dev_stack_ssh_agent_key }}|$WORK/forge|" \
  > "$WORK/converge.sh"
if [ ! -s "$WORK/converge.sh" ]; then
  echo "FAIL - could not extract the snippet from $TASKS"; exit 1
fi

ssh-keygen -q -t ed25519 -N "" -C "forge" -f "$WORK/forge"
ssh-keygen -q -t ed25519 -N "" -C "foreign" -f "$WORK/foreign"
FORGE_FP="$(ssh-keygen -lf "$WORK/forge" | awk '{print $2}')"

export SSH_AUTH_SOCK="$WORK/agent.sock"
restart_agent() {
  pkill -f "ssh-agent -a $SSH_AUTH_SOCK" >/dev/null 2>&1
  rm -f "$SSH_AUTH_SOCK"
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null 2>&1
}

check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then echo "  ok   - $name"
  else echo "  FAIL - $name"; echo "         want: $want"; echo "         got:  $got"
       fails=$((fails + 1)); fi
}

# Report the agent as "<count> keys, forge present yes/no".
state() {
  local out n has
  out="$(ssh-add -l 2>/dev/null)" || out=""
  n=$(printf '%s\n' "$out" | grep -c 'SHA256:' || true)
  if printf '%s\n' "$out" | grep -qF "$FORGE_FP"; then has=yes; else has=no; fi
  echo "$n keys, forge $has"
}

echo "== agent convergence =="

# --- P1: already exactly the forge key -> no change -------------------------
restart_agent; ssh-add -q "$WORK/forge"
out="$(bash "$WORK/converge.sh" 2>&1)"
check "P1: already correct -> converged state"        "$(state)" "1 keys, forge yes"
check "P1: already correct -> reports no change"      "$(printf '%s' "$out" | grep -c 'Identity added' || true)" "0"

# --- P2: forge plus a foreign key -> foreign pruned -------------------------
restart_agent; ssh-add -q "$WORK/forge"; ssh-add -q "$WORK/foreign"
bash "$WORK/converge.sh" >/dev/null 2>&1
check "P2: foreign alongside forge is pruned"         "$(state)" "1 keys, forge yes"

# --- P3: only foreign keys -> pruned, forge added ---------------------------
restart_agent; ssh-add -q "$WORK/foreign"
bash "$WORK/converge.sh" >/dev/null 2>&1
check "P3: only foreign -> pruned and forge added"    "$(state)" "1 keys, forge yes"

# --- P4: empty agent -> forge added ----------------------------------------
restart_agent
bash "$WORK/converge.sh" >/dev/null 2>&1
check "P4: empty agent -> forge added"                "$(state)" "1 keys, forge yes"

# --- P5: a change is reported on STDOUT, where the task's changed_when looks --
# ssh-add writes "Identity added" and "All identities removed." to stderr, so
# the snippet prints its own marker on stdout when it changed the agent.
MARKER="dev-stack: agent converged"
restart_agent; ssh-add -q "$WORK/forge"
out="$(bash "$WORK/converge.sh" 2>/dev/null)"
check "P5: no change -> no marker on stdout"          "$(printf '%s' "$out" | grep -cF "$MARKER" || true)" "0"
restart_agent; ssh-add -q "$WORK/forge"; ssh-add -q "$WORK/foreign"
out="$(bash "$WORK/converge.sh" 2>/dev/null)"
check "P5: pruned -> marker on stdout"                "$(printf '%s' "$out" | grep -cF "$MARKER" || true)" "1"
restart_agent
out="$(bash "$WORK/converge.sh" 2>/dev/null)"
check "P5: added -> marker on stdout"                 "$(printf '%s' "$out" | grep -cF "$MARKER" || true)" "1"
check "P5: changed_when matches the marker on stdout" \
  "$(grep -cF "changed_when: \"'$MARKER' in dev_stack_agent_add.stdout\"" "$TASKS")" "1"

# --- P6: a key that cannot be fingerprinted fails loudly, prunes nothing -----
# An empty fingerprint would make every loaded key count as "mine", so a
# foreign key would never be pruned.
printf 'not a key\n' > "$WORK/garbage"
sed -n '/--- agent-convergence begin/,/--- agent-convergence end/p' "$TASKS" \
  | sed 's/^        //' \
  | sed "s|{{ dev_stack_user_home }}/{{ dev_stack_ssh_agent_key }}|$WORK/garbage|" \
  > "$WORK/converge_bad.sh"
restart_agent; ssh-add -q "$WORK/foreign"
bash "$WORK/converge_bad.sh" >/dev/null 2>&1; rc=$?
check "P6: unreadable key -> non-zero exit"           "$([ "$rc" -ne 0 ] && echo nonzero || echo zero)" "nonzero"
check "P6: unreadable key -> agent left untouched"    "$(state)" "1 keys, forge no"

echo
if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; fi
exit "$fails"
