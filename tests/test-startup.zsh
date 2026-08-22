#!/usr/bin/env zsh
# Integration tests for sc-zsh startup and functionality
# Usage: zsh tests/test-startup.zsh

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Disable job control in test runner to prevent terminal suspension (SIGTTIN/SIGTTOU)
unsetopt MONITOR 2>/dev/null || true

# Test helper functions
pass() {
    echo "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

echo "Running sc-zsh integration tests..."
echo "====================================\n"

# Test 1: Verify startup time < 0.3s using SC_PROFILE=1
echo "Test 1: Startup time verification"
STARTUP_OUTPUT=$(SC_PROFILE=1 zsh -i +m -c 'exit' </dev/null 2>&1)
# Calculate total from SOURCED lines
STARTUP_TIME=$(echo "$STARTUP_OUTPUT" | grep "^SOURCED" | awk '{sum += $NF} END {printf "%.4f", sum}' | sed 's/s//')
if [[ -n "$STARTUP_TIME" ]] && (( $(echo "$STARTUP_TIME > 0" | bc -l) )); then
    if (( $(echo "$STARTUP_TIME < 0.3" | bc -l) )); then
        pass "Startup time: ${STARTUP_TIME}s (< 0.3s target)"
    else
        fail "Startup time: ${STARTUP_TIME}s (exceeds 0.3s target)"
    fi
else
    fail "Could not measure startup time"
fi

# Test 2: Check for error messages during startup
echo "\nTest 2: Startup error check"
STARTUP_ERRORS=$(zsh -i +m -c 'exit' </dev/null 2>&1 | grep -iE 'error|fail|warn' || true)
if [[ -z "$STARTUP_ERRORS" ]]; then
    pass "No errors during startup"
else
    fail "Errors found during startup:\n$STARTUP_ERRORS"
fi

# Test 3: Verify all expected functions are loaded
echo "\nTest 3: Function loading verification"
FUNCTIONS_CHECK=$(zsh -i +m -c 'which ql rm.dstore' </dev/null 2>&1)
if echo "$FUNCTIONS_CHECK" | grep -q "ql" && \
   echo "$FUNCTIONS_CHECK" | grep -q "rm.dstore"; then
    pass "All expected functions loaded (ql, rm.dstore)"
else
    fail "Not all expected functions loaded"
fi

# Test 4: Verify PATH includes expected directories
echo "\nTest 4: PATH verification"
PATH_CHECK=$(zsh -i +m -c 'echo $PATH' </dev/null 2>&1)
MISSING_PATHS=()

# Check for Homebrew path (at least one should exist)
if ! echo "$PATH_CHECK" | grep -qE '(/opt/homebrew/bin|/usr/local/bin|/home/linuxbrew)'; then
    MISSING_PATHS+=("Homebrew bin")
fi

# Check for user paths (if they exist on system)
[[ -d "$HOME/.local/bin" ]] && ! echo "$PATH_CHECK" | grep -q "$HOME/.local/bin" && MISSING_PATHS+=("$HOME/.local/bin")
[[ -d "$HOME/go/bin" ]] && ! echo "$PATH_CHECK" | grep -q "$HOME/go/bin" && MISSING_PATHS+=("$HOME/go/bin")

if [[ ${#MISSING_PATHS[@]} -eq 0 ]]; then
    pass "PATH includes expected directories"
else
    fail "PATH missing directories: ${MISSING_PATHS[*]}"
fi

# Test 5: Verify ZDOTDIR is set correctly
echo "\nTest 5: ZDOTDIR verification"
ZDOTDIR_CHECK=$(zsh +m -c 'echo $ZDOTDIR' </dev/null 2>&1)
EXPECTED_ZDOTDIR="${0:A:h:h}"  # Derive from script location (tests/../)
if [[ "$ZDOTDIR_CHECK" == "$EXPECTED_ZDOTDIR" ]]; then
    pass "ZDOTDIR set correctly: $ZDOTDIR_CHECK"
else
    fail "ZDOTDIR incorrect. Expected: $EXPECTED_ZDOTDIR, Got: $ZDOTDIR_CHECK"
fi

# Test 6: Verify ZSH_CACHE_DIR is set correctly
echo "\nTest 6: ZSH_CACHE_DIR verification"
CACHE_DIR_CHECK=$(zsh -i +m -c 'echo $ZSH_CACHE_DIR' </dev/null 2>&1)
EXPECTED_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [[ "$CACHE_DIR_CHECK" == "$EXPECTED_CACHE_DIR" ]]; then
    pass "ZSH_CACHE_DIR set correctly: $CACHE_DIR_CHECK"
else
    fail "ZSH_CACHE_DIR incorrect. Expected: $EXPECTED_CACHE_DIR, Got: $CACHE_DIR_CHECK"
fi

# Summary
echo "\n===================================="
echo "Test Results"
echo "===================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo "\n${RED}Some tests failed.${NC}"
    exit 1
fi
