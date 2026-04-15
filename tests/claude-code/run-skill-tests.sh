#!/usr/bin/env bash
# Test runner for autoresearch Claude Code skills
# Runs fast harness checks and optionally live integration tests.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure ripgrep is available — Claude Code vendors its own rg binary
if ! command -v rg &>/dev/null; then
    # Try the Claude Code vendor path (arm64-darwin and x64-darwin)
    for _rg_dir in \
        "$HOME/.nvm/versions/node"/*/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin \
        "$HOME/.nvm/versions/node"/*/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/x64-darwin \
        /usr/local/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin \
        /usr/local/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/x64-darwin; do
        if [ -x "$_rg_dir/rg" ]; then
            export PATH="$_rg_dir:$PATH"
            break
        fi
    done
fi

# Source helpers from superpowers-main if available, otherwise define minimal stubs
HELPERS="$SCRIPT_DIR/test-helpers.sh"
if [ ! -f "$HELPERS" ]; then
    # Minimal stubs so fast harness tests work without the full superpowers helpers
    run_with_timeout() { local s="$1"; shift; "$@"; }
    run_test_with_capture() { local t="$1"; local l="$2"; shift 2; "$@" 2>&1 | tee "$l"; return "${PIPESTATUS[0]}"; }
    init_research_artifact_dir() { :; }
    export -f run_with_timeout run_test_with_capture init_research_artifact_dir
fi

echo "========================================"
echo " Autoresearch Skills Test Suite"
echo "========================================"
echo ""
echo "Repository: $(cd ../.. && pwd)"
echo "Test time: $(date)"
echo ""

# Parse command line arguments
VERBOSE=false
SPECIFIC_TEST=""
TIMEOUT=300
RUN_AUTORESEARCH_INTEGRATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --test|-t)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --autoresearch-integration)
            RUN_AUTORESEARCH_INTEGRATION=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v                Show verbose output"
            echo "  --test, -t NAME              Run only the specified test"
            echo "  --timeout SECONDS            Set timeout per test (default: 300)"
            echo "  --autoresearch-integration   Run autoresearch live integration tests (slow)"
            echo "  --help, -h                   Show this help"
            echo ""
            echo "Fast Tests (run by default):"
            echo "  test-autoresearch-brainstorming-harness.sh          Static brainstorming contract checks"
            echo "  test-autoresearch-loop-harness.sh                   Static loop contract checks"
            echo "  test-autoresearch-planning-harness.sh               Static planning contract checks"
            echo "  test-autoresearch-bootstrap-harness.sh              Static bootstrap contract checks"
            echo "  ../release-readiness/test-readme-install-surface.sh Release-readiness docs/install checks"
            echo ""
            echo "Autoresearch Live Integration Tests (use --autoresearch-integration):"
            echo "  test-autoresearch-brainstorming-integration.sh      Brainstorming artifact generation"
            echo "  test-autoresearch-brainstorming-spec-reviewer.sh    Spec reviewer catches intentional errors"
            echo "  test-autoresearch-bootstrap-integration.sh          Bootstrap artifact generation"
            echo "  test-autoresearch-loop-integration.sh               Loop gate/contract execution"
            echo "  test-autoresearch-planning-reviewer.sh              Planning reviewer catches intentional errors"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Fast harness tests (no Claude invocation needed)
fast_tests=(
    "test-autoresearch-brainstorming-harness.sh"
    "test-autoresearch-loop-harness.sh"
    "test-autoresearch-planning-harness.sh"
    "test-autoresearch-bootstrap-harness.sh"
    "../release-readiness/test-readme-install-surface.sh"
)

# Live integration tests (invoke Claude CLI, slow)
autoresearch_integration_tests=(
    "test-autoresearch-brainstorming-integration.sh"
    "test-autoresearch-brainstorming-spec-reviewer.sh"
    "test-autoresearch-bootstrap-integration.sh"
    "test-autoresearch-loop-integration.sh"
    "test-autoresearch-planning-reviewer.sh"
)

# Build the test list
if [ -n "$SPECIFIC_TEST" ]; then
    tests=("$SPECIFIC_TEST")
elif [ "$RUN_AUTORESEARCH_INTEGRATION" = true ]; then
    tests=("${autoresearch_integration_tests[@]}")
else
    tests=("${fast_tests[@]}")
fi

# Track results
passed=0
failed=0
skipped=0

for test in "${tests[@]}"; do
    echo "----------------------------------------"
    echo "Running: $test"
    echo "----------------------------------------"

    test_path="$SCRIPT_DIR/$test"

    if [ ! -f "$test_path" ]; then
        echo "  [SKIP] Test file not found: $test"
        skipped=$((skipped + 1))
        echo ""
        continue
    fi

    if [ ! -x "$test_path" ]; then
        chmod +x "$test_path"
    fi

    start_time=$(date +%s)

    if [ "$VERBOSE" = true ]; then
        if bash "$test_path"; then
            end_time=$(date +%s)
            echo "  [PASS] $test ($((end_time - start_time))s)"
            passed=$((passed + 1))
        else
            end_time=$(date +%s)
            echo "  [FAIL] $test ($((end_time - start_time))s)"
            failed=$((failed + 1))
        fi
    else
        if output=$(bash "$test_path" 2>&1); then
            end_time=$(date +%s)
            echo "  [PASS] ($((end_time - start_time))s)"
            passed=$((passed + 1))
        else
            end_time=$(date +%s)
            echo "  [FAIL] ($((end_time - start_time))s)"
            echo ""
            echo "  Output:"
            echo "$output" | sed 's/^/    /'
            failed=$((failed + 1))
        fi
    fi

    echo ""
done

echo "========================================"
echo " Test Results Summary"
echo "========================================"
echo ""
echo "  Passed:  $passed"
echo "  Failed:  $failed"
echo "  Skipped: $skipped"
echo ""

if [ "$RUN_AUTORESEARCH_INTEGRATION" = false ] && [ -z "$SPECIFIC_TEST" ]; then
    echo "Note: Autoresearch live integration tests were not run (they require Claude CLI and take 10-30 minutes)."
    echo "Use --autoresearch-integration to run them."
    echo ""
fi

if [ $failed -gt 0 ]; then
    echo "STATUS: FAILED"
    exit 1
else
    echo "STATUS: PASSED"
    exit 0
fi
