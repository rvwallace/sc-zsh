# sc-zsh Integration Tests

This directory contains integration tests for the sc-zsh configuration system.

## Running Tests

### Run all tests

```bash
zsh tests/test-startup.zsh
```

Or make it executable and run directly:

```bash
chmod +x tests/test-startup.zsh
./tests/test-startup.zsh
```

## Test Coverage

### test-startup.zsh

**Test 1: Startup Time Verification**
- Measures shell startup time using `SC_PROFILE=1`
- Passes if startup time < 0.3s
- Current target: < 0.3s (actual: ~0.17s)

**Test 2: Startup Error Check**
- Verifies no errors or warnings during startup
- Excludes known informational messages (e.g., zsh-you-should-use)

**Test 3: Function Loading Verification**
- Checks that core autoload functions are available
- Expected functions: `ql`, `rm.dstore`

**Test 4: PATH Verification**
- Verifies PATH includes expected directories
- Checks for Homebrew paths
- Checks for user-specific paths (if directories exist)

**Test 5: ZDOTDIR Verification**
- Confirms ZDOTDIR is set to the correct project directory
- Required for proper sc-zsh initialization

## Test Output

Tests use color-coded output:
- ✓ Green: Test passed
- ✗ Red: Test failed

Example output:
```
Running sc-zsh integration tests...
====================================

Test 1: Startup time verification
✓ Startup time: 0.17s (< 0.3s target)

Test 2: Startup error check
✓ No errors during startup

...

====================================
Test Results
====================================
Passed: 5
Failed: 0
Total:  5

All tests passed!
```

## Adding New Tests

To add a new test:

1. Follow the existing test pattern in `test-startup.zsh`
2. Use the `pass()` and `fail()` helper functions
3. Update this README with test description
4. Increment test counters appropriately

Example:
```zsh
echo "\nTest 6: New test description"
RESULT=$(zsh -i -c 'some command' 2>&1)
if [[ "$RESULT" == "expected" ]]; then
    pass "New test passed"
else
    fail "New test failed: $RESULT"
fi
```

## CI Integration

These tests can be integrated into GitHub Actions or other CI systems:

```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: zsh tests/test-startup.zsh
```

## Requirements

- Zsh 5.0+
- bc (for floating-point comparison in startup time test)

## Troubleshooting

**Test failures after modifications:**
1. Check syntax: `zsh -n <modified-file>`
2. Test sourcing: `zsh -c 'source <modified-file>'`
3. Profile startup: `SC_PROFILE=1 zsh -i -c 'exit'`

**Permission errors:**
- Ensure test scripts are executable: `chmod +x tests/*.zsh`

**PATH test failures:**
- Verify expected directories exist on your system
- Tests skip directories that don't exist

## Future Enhancements

Potential additions:
- Plugin loading tests
- Completion system tests
- Performance benchmarks
- Integration with external tools (fzf, zoxide, etc.)
- Cross-platform tests (macOS, Linux)
