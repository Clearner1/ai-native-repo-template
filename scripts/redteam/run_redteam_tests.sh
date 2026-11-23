#!/usr/bin/env bash
# run_redteam_tests.sh — Red Team Stress Testing Battery for AI Harness
set -uo pipefail

WORKTREE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$WORKTREE_DIR"

TMP_DIR="$(mktemp -d /tmp/redteam_test.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

TOTAL=0
BLOCKED_COUNT=0
BYPASS_COUNT=0

results_table=""

record_result() {
  local id="$1"
  local category="$2"
  local scenario="$3"
  local guard="$4"
  local outcome="$5" # BLOCKED or BYPASSED
  local note="$6"

  TOTAL=$((TOTAL + 1))
  if [ "$outcome" == "BLOCKED" ]; then
    BLOCKED_COUNT=$((BLOCKED_COUNT + 1))
  else
    BYPASS_COUNT=$((BYPASS_COUNT + 1))
  fi

  results_table+="${id} | ${category} | ${scenario} | ${guard} | ${outcome} | ${note}\n"
}

echo "=== Starting Red Team Stress Test Battery ==="

# ==========================================
# Group 1: Repository Gate & Changeset Tests
# ==========================================

# G1.1: Missing Changeset when changing code
pr_no_changeset="$TMP_DIR/pr_no_changeset.md"
cat << 'EOF' > "$pr_no_changeset"
## 1. Intent & Context
- **Problem / Goal**: Add core feature
- **Issue Reference**: #123

## 2. Alternatives Considered & Rejected
- **Rejected Alternative**: Do nothing

## 3. Risk Tier & Sensitive Paths
- [x] **Tier 1 (Normal Review)**

## 4. Reverse Verification
- **Verification Mode**: `red-green`
- **RED (Failure Proof)**:
```text
FAIL: test_something
```
- **GREEN (Passing Proof)**:
```text
PASS: test_something
```

## 5. Observability & Changeset Square
- **Changeset Fragment**: auto
EOF

if ./scripts/verify/pr-contract-check.sh "$pr_no_changeset" >/dev/null 2>&1; then
  record_result "G1.1" "PR Contract" "PR body without changeset diff or none" "pr-contract-check.sh" "BLOCKED" "Requires BASE_SHA/HEAD_SHA env to trigger diff check; body syntax passes."
fi

# G1.2: AGENTS.md Size Overflow
cp AGENTS.md "$TMP_DIR/AGENTS.md.bak"
python3 -c "print('A' * 17000)" >> AGENTS.md
if ./scripts/verify/repo-gate.sh > "$TMP_DIR/out_g12.log" 2>&1; then
  record_result "G1.2" "Repo Gate" "AGENTS.md byte bloat (>16KB)" "repo-gate.sh" "BYPASSED" "Failed to block oversized AGENTS.md"
else
  record_result "G1.2" "Repo Gate" "AGENTS.md byte bloat (>16KB)" "repo-gate.sh" "BLOCKED" "Blocked with AX ceiling violation"
fi
cp "$TMP_DIR/AGENTS.md.bak" AGENTS.md

# G1.3: Unregistered Skill in AGENTS.md
mkdir -p .agents/skills/rogue-skill
cat << 'EOF' > .agents/skills/rogue-skill/SKILL.md
---
name: rogue-skill
description: Rogue un-indexed skill
---
Rogue skill body
EOF
if ./scripts/verify/repo-gate.sh > "$TMP_DIR/out_g13.log" 2>&1; then
  record_result "G1.3" "Repo Gate" "Unregistered skill folder" "repo-gate.sh" "BYPASSED" "Failed to detect unregistered skill"
else
  record_result "G1.3" "Repo Gate" "Unregistered skill folder" "repo-gate.sh" "BLOCKED" "Blocked with unindexed skill error"
fi
rm -rf .agents/skills/rogue-skill

# G1.4: Monolithic CHANGELOG.md creation
touch CHANGELOG.md
if ./scripts/verify/repo-gate.sh > "$TMP_DIR/out_g14.log" 2>&1; then
  record_result "G1.4" "Repo Gate" "Monolithic CHANGELOG.md" "repo-gate.sh" "BYPASSED" "Failed to reject root CHANGELOG.md"
else
  record_result "G1.4" "Repo Gate" "Monolithic CHANGELOG.md" "repo-gate.sh" "BLOCKED" "Blocked monolithic CHANGELOG.md"
fi
rm -f CHANGELOG.md

# G1.5a: LESSONS.md Unpromoted Seen 3x Entry in Active Section
cp LESSONS.md "$TMP_DIR/LESSONS.md.bak"
python3 -c "
with open('LESSONS.md', 'r') as f:
    content = f.read()
idx = content.find('## Moved to the code standards')
new_content = content[:idx] + '\n- Seen 3x (2026-11-20, 2026-11-21, 2026-11-22): Leaking goroutine.\n\n' + content[idx:]
with open('LESSONS.md', 'w') as f:
    f.write(new_content)
"
if ./scripts/verify/lessons-check.sh > "$TMP_DIR/out_g15a.log" 2>&1; then
  record_result "G1.5a" "Lessons Gate" "Active lesson with Seen >= 3x" "lessons-check.sh" "BYPASSED" "Failed to block unpromoted Seen 3x"
else
  record_result "G1.5a" "Lessons Gate" "Active lesson with Seen >= 3x" "lessons-check.sh" "BLOCKED" "Blocked unpromoted Seen 3x in active section"
fi
cp "$TMP_DIR/LESSONS.md.bak" LESSONS.md

# G1.5b: Premature placement under Moved to code standards without actual promotion
cp LESSONS.md "$TMP_DIR/LESSONS.md.bak"
cat << 'EOF' >> LESSONS.md
- Seen 3x (2026-11-20, 2026-11-21, 2026-11-22): Leaking goroutine.
EOF
if ./scripts/verify/lessons-check.sh > "$TMP_DIR/out_g15b.log" 2>&1; then
  record_result "G1.5b" "Lessons Gate" "Bypass active check by appending after Moved to code standards" "lessons-check.sh" "BYPASSED" "Blindspot: lessons placed in/after archive section skip validation without checking code-standards.md"
else
  record_result "G1.5b" "Lessons Gate" "Bypass active check by appending after Moved to code standards" "lessons-check.sh" "BLOCKED" "Caught lesson placed in archive section"
fi
cp "$TMP_DIR/LESSONS.md.bak" LESSONS.md

# ==========================================
# Group 2: PR Contract Check Scenarios
# ==========================================

# P2.1: Blank Problem/Goal
pr_blank="$TMP_DIR/pr_blank.md"
cat << 'EOF' > "$pr_blank"
## 1. Intent & Context
- **Problem / Goal**: 
- **Issue Reference**: #123
## 2. Alternatives Considered & Rejected
- **Rejected Alternative**: None
## 3. Risk Tier & Sensitive Paths
- [x] **Tier 1 (Normal Review)**
## 4. Reverse Verification
- **Verification Mode**: `red-green`
- **RED (Failure Proof)**: `failed`
- **GREEN (Passing Proof)**: `passed`
## 5. Observability & Changeset Square
- **Changeset Fragment**: none
EOF
if ./scripts/verify/pr-contract-check.sh "$pr_blank" > "$TMP_DIR/out_p21.log" 2>&1; then
  record_result "P2.1" "PR Contract" "Blank Problem/Goal" "pr-contract-check.sh" "BYPASSED" "Passed empty Problem/Goal"
else
  record_result "P2.1" "PR Contract" "Blank Problem/Goal" "pr-contract-check.sh" "BLOCKED" "Blocked blank Problem/Goal"
fi

# P2.2: Fake Empty RED / GREEN Evidence Block
pr_empty_evidence="$TMP_DIR/pr_empty_evidence.md"
cat << 'EOF' > "$pr_empty_evidence"
## 1. Intent & Context
- **Problem / Goal**: Real problem
- **Issue Reference**: #123
## 2. Alternatives Considered & Rejected
- **Rejected Alternative**: Real alternative
## 3. Risk Tier & Sensitive Paths
- [x] **Tier 1 (Normal Review)**
## 4. Reverse Verification
- **Verification Mode**: `red-green`
- **RED (Failure Proof)**:
```text
```
- **GREEN (Passing Proof)**:
```text
```
## 5. Observability & Changeset Square
- **Changeset Fragment**: none
EOF
if ./scripts/verify/pr-contract-check.sh "$pr_empty_evidence" > "$TMP_DIR/out_p22.log" 2>&1; then
  record_result "P2.2" "PR Contract" "Empty RED/GREEN code fences" "pr-contract-check.sh" "BYPASSED" "Passed empty RED/GREEN evidence"
else
  record_result "P2.2" "PR Contract" "Empty RED/GREEN code fences" "pr-contract-check.sh" "BLOCKED" "Blocked empty RED/GREEN evidence blocks"
fi

# P2.3: Untracked Sensitive Path with Tier 1 Check in local mode
pr_tier1_sensitive="$TMP_DIR/pr_tier1_sensitive.md"
cat << 'EOF' > "$pr_tier1_sensitive"
## 1. Intent & Context
- **Problem / Goal**: Touch CODEOWNERS
- **Issue Reference**: #123
## 2. Alternatives Considered & Rejected
- **Rejected Alternative**: None
## 3. Risk Tier & Sensitive Paths
- [x] **Tier 1 (Normal Review)**
## 4. Reverse Verification
- **Verification Mode**: `docs-only`
## 5. Observability & Changeset Square
- **Changeset Fragment**: none
EOF
if ./scripts/verify/pr-contract-check.sh "$pr_tier1_sensitive" > "$TMP_DIR/out_p23.log" 2>&1; then
  record_result "P2.3" "PR Contract" "CODEOWNERS modified under Tier 1 (local run)" "pr-contract-check.sh" "BYPASSED" "Only checked when BASE_SHA/HEAD_SHA provided in CI; local check passed"
else
  record_result "P2.3" "PR Contract" "CODEOWNERS modified under Tier 1 (local run)" "pr-contract-check.sh" "BLOCKED" "Blocked sensitive path on Tier 1"
fi

# ==========================================
# Group 3: Mechanical Guard Tests Scenarios
# ==========================================

# S3.1a: Direct time.Sleep (Go) in test file
test_go_sleep="$TMP_DIR/sample_test.go"
cat << 'EOF' > "$test_go_sleep"
package sample_test
import "time"
func TestSample(t *testing.T) {
    time.Sleep(10 * time.Millisecond)
}
EOF
if bash tests/guards/guard_no_sleep.sh "$TMP_DIR" > "$TMP_DIR/out_s31a.log" 2>&1; then
  record_result "S3.1a" "Guard Tests" "Direct time.Sleep in Go test" "guard_no_sleep.sh" "BYPASSED" "Failed to catch time.Sleep"
else
  record_result "S3.1a" "Guard Tests" "Direct time.Sleep in Go test" "guard_no_sleep.sh" "BLOCKED" "Caught time.Sleep"
fi
rm -f "$test_go_sleep"

# S3.1b: Go <-time.After() in test file
test_go_after="$TMP_DIR/sample_test.go"
cat << 'EOF' > "$test_go_after"
package sample_test
import "time"
func TestSample(t *testing.T) {
    select {
    case <-time.After(100 * time.Millisecond):
    }
}
EOF
if bash tests/guards/guard_no_sleep.sh "$TMP_DIR" > "$TMP_DIR/out_s31b.log" 2>&1; then
  record_result "S3.1b" "Guard Tests" "Go <-time.After in test file" "guard_no_sleep.sh" "BYPASSED" "Blindspot: time.After not matched by time\.Sleep"
else
  record_result "S3.1b" "Guard Tests" "Go <-time.After in test file" "guard_no_sleep.sh" "BLOCKED" "Caught time.After"
fi
rm -f "$test_go_after"

# S3.1c: Python aliased sleep import
test_py_alias="$TMP_DIR/test_alias.py"
cat << 'EOF' > "$test_py_alias"
from time import sleep as s
def test_delay():
    s(0.5)
EOF
if bash tests/guards/guard_no_sleep.sh "$TMP_DIR" > "$TMP_DIR/out_s31c.log" 2>&1; then
  record_result "S3.1c" "Guard Tests" "Python aliased sleep (from time import sleep as s)" "guard_no_sleep.sh" "BYPASSED" "Blindspot: aliased call s() evades regex"
else
  record_result "S3.1c" "Guard Tests" "Python aliased sleep (from time import sleep as s)" "guard_no_sleep.sh" "BLOCKED" "Caught aliased sleep"
fi
rm -f "$test_py_alias"

# S3.2a: Unittest assertEqual(str(x), ...)
test_py_mirror_unittest="$TMP_DIR/test_mirror.py"
cat << 'EOF' > "$test_py_mirror_unittest"
def test_foo(self):
    self.assertEqual(str(obj), "foo")
EOF
if bash tests/guards/guard_no_mirror_assert.sh "$TMP_DIR" > "$TMP_DIR/out_s32a.log" 2>&1; then
  record_result "S3.2a" "Guard Tests" "Unittest assertEqual(str(obj))" "guard_no_mirror_assert.sh" "BYPASSED" "Failed to catch assertEqual(str(obj))"
else
  record_result "S3.2a" "Guard Tests" "Unittest assertEqual(str(obj))" "guard_no_mirror_assert.sh" "BLOCKED" "Caught assertEqual(str(obj))"
fi
rm -f "$test_py_mirror_unittest"

# S3.2b: Pytest assert str(obj) == expected
test_py_mirror_pytest="$TMP_DIR/test_mirror_pytest.py"
cat << 'EOF' > "$test_py_mirror_pytest"
def test_foo():
    assert str(obj) == "foo"
EOF
if bash tests/guards/guard_no_mirror_assert.sh "$TMP_DIR" > "$TMP_DIR/out_s32b.log" 2>&1; then
  record_result "S3.2b" "Guard Tests" "Pytest assert str(obj) == 'foo'" "guard_no_mirror_assert.sh" "BYPASSED" "Blindspot: only matches assertEqual, pytest assert str(...) passes!"
else
  record_result "S3.2b" "Guard Tests" "Pytest assert str(obj) == 'foo'" "guard_no_mirror_assert.sh" "BLOCKED" "Caught pytest assert str"
fi
rm -f "$test_py_mirror_pytest"

# S3.2c: Python f-string mirror assert f"{obj}" == "foo"
test_py_fstring="$TMP_DIR/test_fstring.py"
cat << 'EOF' > "$test_py_fstring"
def test_foo():
    assert f"{obj}" == "foo"
EOF
if bash tests/guards/guard_no_mirror_assert.sh "$TMP_DIR" > "$TMP_DIR/out_s32c.log" 2>&1; then
  record_result "S3.2c" "Guard Tests" "Python f-string mirror assert f\"{obj}\" == 'foo'" "guard_no_mirror_assert.sh" "BYPASSED" "Blindspot: f-string interpolation evades mirror guard"
else
  record_result "S3.2c" "Guard Tests" "Python f-string mirror assert f\"{obj}\" == 'foo'" "guard_no_mirror_assert.sh" "BLOCKED" "Caught f-string mirror assert"
fi
rm -f "$test_py_fstring"

# S3.3a: Multi-line bare default
test_catchall_multiline="$TMP_DIR/test_switch.go"
cat << 'EOF' > "$test_catchall_multiline"
package main
func handle(v int) {
    switch v {
    case 1:
        println(1)
    default:
        return
    }
}
EOF
if bash tests/guards/guard_no_catchall.sh "$TMP_DIR" > "$TMP_DIR/out_s33a.log" 2>&1; then
  record_result "S3.3a" "Guard Tests" "Multi-line silent default: return" "guard_no_catchall.sh" "BYPASSED" "Failed to catch silent default"
else
  record_result "S3.3a" "Guard Tests" "Multi-line silent default: return" "guard_no_catchall.sh" "BLOCKED" "Caught multi-line silent default"
fi
rm -f "$test_catchall_multiline"

# S3.3b: Single-line default: return
test_catchall_singleline="$TMP_DIR/test_switch_single.go"
cat << 'EOF' > "$test_catchall_singleline"
package main
func handle(v int) {
    switch v {
    case 1: println(1)
    default: return
    }
}
EOF
if bash tests/guards/guard_no_catchall.sh "$TMP_DIR" > "$TMP_DIR/out_s33b.log" 2>&1; then
  record_result "S3.3b" "Guard Tests" "Single-line default: return" "guard_no_catchall.sh" "BYPASSED" "Blindspot: 'default:\s*$' requires trailing newline; single line evades"
else
  record_result "S3.3b" "Guard Tests" "Single-line default: return" "guard_no_catchall.sh" "BLOCKED" "Caught single-line default"
fi
rm -f "$test_catchall_singleline"

# S3.4a: Multi-hop defensive field guessing
test_guess="$TMP_DIR/guess.ts"
cat << 'EOF' > "$test_guess"
const uid = payload.userId ?? payload.user_id ?? payload.id;
EOF
if bash tests/guards/guard_no_defensive_guess.sh "$TMP_DIR" > "$TMP_DIR/out_s34a.log" 2>&1; then
  record_result "S3.4a" "Guard Tests" "Chained fallback: payload.userId ?? payload.user_id ?? payload.id" "guard_no_defensive_guess.sh" "BYPASSED" "Failed to catch chained fallback"
else
  record_result "S3.4a" "Guard Tests" "Chained fallback: payload.userId ?? payload.user_id ?? payload.id" "guard_no_defensive_guess.sh" "BLOCKED" "Caught chained fallback"
fi
rm -f "$test_guess"

# S3.4b: Opt-out comment hole in guard_no_defensive_guess.sh
test_guess_optout="$TMP_DIR/guess_optout.ts"
cat << 'EOF' > "$test_guess_optout"
// guard:no-defensive-guess:ignore
const uid = payload.userId ?? payload.user_id ?? payload.id;
EOF
if bash tests/guards/guard_no_defensive_guess.sh "$TMP_DIR" > "$TMP_DIR/out_s34b.log" 2>&1; then
  record_result "S3.4b" "Guard Tests" "Abuse // guard:no-defensive-guess:ignore header" "guard_no_defensive_guess.sh" "BYPASSED" "Backdoor: file-wide ignore comment completely disables guard"
else
  record_result "S3.4b" "Guard Tests" "Abuse // guard:no-defensive-guess:ignore header" "guard_no_defensive_guess.sh" "BLOCKED" "Blocked even with ignore comment"
fi
rm -f "$test_guess_optout"

# S3.5a: Raw exec.Command bypassing proc.Command (Missing guard)
test_exec_bypass="$TMP_DIR/bypass_exec.go"
cat << 'EOF' > "$test_exec_bypass"
package main
import "os/exec"
func run() {
    exec.Command("ls").Run()
}
EOF
if bash tests/guards/run_all.sh > "$TMP_DIR/out_s35a.log" 2>&1; then
  record_result "S3.5a" "Missing Guard" "Raw exec.Command bypassing proc wrapper" "none" "BYPASSED" "No guard checks for raw os/exec or subprocess.Popen"
else
  record_result "S3.5a" "Missing Guard" "Raw exec.Command bypassing proc wrapper" "none" "BLOCKED" "Caught raw exec"
fi
rm -f "$test_exec_bypass"

# S3.5b: Fake green test with 'assert True' (Missing guard)
test_fake_pass="$TMP_DIR/test_fake.py"
cat << 'EOF' > "$test_fake_pass"
def test_critical_feature():
    assert True
EOF
if bash tests/guards/run_all.sh > "$TMP_DIR/out_s35b.log" 2>&1; then
  record_result "S3.5b" "Missing Guard" "Fake green test with 'assert True'" "none" "BYPASSED" "No guard checks for tautological assert True or pass"
else
  record_result "S3.5b" "Missing Guard" "Fake green test with 'assert True'" "none" "BLOCKED" "Caught fake assert True"
fi
rm -f "$test_fake_pass"

# S3.5c: Live network leakage in test file (Missing guard)
test_net_leak="$TMP_DIR/test_net.py"
cat << 'EOF' > "$test_net_leak"
import urllib.request
def test_api():
    resp = urllib.request.urlopen("https://api.example.com")
EOF
if bash tests/guards/run_all.sh > "$TMP_DIR/out_s35c.log" 2>&1; then
  record_result "S3.5c" "Missing Guard" "Live network call in test file" "none" "BYPASSED" "No guard checks for live URLs or urllib/requests/net in tests"
else
  record_result "S3.5c" "Missing Guard" "Live network call in test file" "none" "BLOCKED" "Caught live network call"
fi
rm -f "$test_net_leak"

echo "=== Battery Complete ==="
echo "Total tests: $TOTAL"
echo "Blocked: $BLOCKED_COUNT"
echo "Bypassed / Blindspots: $BYPASS_COUNT"

printf "%b" "$results_table"
exit 0
