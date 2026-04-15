#!/usr/bin/env bash
# Helper functions for Claude Code skill tests

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
        return
    fi

    python3 -c '
import subprocess
import sys

timeout = int(sys.argv[1])
command = sys.argv[2:]

try:
    result = subprocess.run(command, timeout=timeout, check=False)
    raise SystemExit(result.returncode)
except subprocess.TimeoutExpired:
    raise SystemExit(124)
' "$seconds" "$@"
}

research_artifact_base="${RESEARCH_ARTIFACT_BASE:-/tmp/claude-research-integration}"

init_research_artifact_dir() {
    if [ -n "${CLAUDE_RESEARCH_INTEGRATION_ARTIFACT_DIR:-}" ]; then
        return 0
    fi

    local timestamp
    timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
    local id
    id=$(printf "%s-%06d" "$timestamp" "$RANDOM")
    local run_dir="$research_artifact_base/research-integration-$id"
    mkdir -p "$run_dir"
    ln -sf "$run_dir" "$research_artifact_base/latest"
    export CLAUDE_RESEARCH_INTEGRATION_ARTIFACT_DIR="$run_dir"
    export CLAUDE_RESEARCH_INTEGRATION_RUN_LOG="$run_dir/runner.log"
    export CLAUDE_RESEARCH_INTEGRATION_FAILURE_LOG="$run_dir/failure-classification.log"
}

classify_failure_type() {
    local log_file="$1"
    local exit_code="$2"

    local content=""
    if [ -r "$log_file" ]; then
        content=$(tr '[:upper:]' '[:lower:]' < "$log_file")
    fi

    if grep -qE "unknown skill|skill not found|disabled skill|skill discovery|available skills are|skill[^[:cntrl:]]*(isn'?t|not)[[:space:]]+available" \
        <<<"$content"; then
        printf 'skill discoverability'
        return
    fi

    if grep -qE \
        'api error|unable to connect to api|enotfound|could not resolve host|connection refused|connection reset|connection timed out|tls handshake|socket hang up|dial tcp|econnreset|econnrefused|failed to fetch|network request failed|service unavailable|error_status[^[:cntrl:]]*429|rate_limit|503|502|504' \
        <<<"$content"; then
        printf 'API/network'
        return
    fi

    if [ "$exit_code" -eq 124 ]; then
        printf 'generic test failure'
        return
    fi

    printf 'generic test failure'
}

run_test_with_capture() {
    local timeout="$1"
    local log_file="$2"
    shift 2
    mkdir -p "$(dirname "$log_file")"

    set +e
    if command -v tee >/dev/null 2>&1; then
        run_with_timeout "$timeout" "$@" 2>&1 | tee "$log_file"
    else
        run_with_timeout "$timeout" "$@" > "$log_file" 2>&1
    fi
    local exit_code=${PIPESTATUS[0]}
    set -e

    return "$exit_code"
}

run_with_timeout_to_output() {
    local seconds="$1"
    local output_file="$2"
    shift 2

    set +e
    run_with_timeout "$seconds" "$@" 2>&1 | tee "$output_file"
    local exit_code=${PIPESTATUS[0]}
    set -e
    return "$exit_code"
}

run_claude() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local output_file
    output_file=$(mktemp)

    local cmd="claude -p \"$prompt\""
    if [ -n "$allowed_tools" ]; then
        cmd="$cmd --allowed-tools=$allowed_tools"
    fi

    if run_with_timeout "$timeout" bash -c "$cmd" > "$output_file" 2>&1; then
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        cat "$output_file" >&2
        rm -f "$output_file"
        return $exit_code
    fi
}

output_suggests_generic_execution_handoff() {
    local output_file="$1"

    awk '
    BEGIN {
        found = 0
    }
    {
        line = tolower($0)
        gsub(/[`"'"'"']/, "", line)

        if (line ~ /(do not|dont|will not|wont|cannot|cant|never)[[:space:]]+use[[:space:]]+(writing-plans|executing-plans|subagent-driven-development)/) {
            next
        }
        if (line ~ /(do not|dont|will not|wont|cannot|cant|never)[[:space:]]+use[[:space:]]+generic planning/) {
            next
        }
        if (line ~ /do not hand off to generic (planning|execution) skills/) {
            next
        }
        if (line ~ /(do not|dont|will not|wont|cannot|cant|never)[[:space:]]+hand off to generic (planning|execution) skills/) {
            next
        }
        if (line ~ /(do not|dont|will not|wont|cannot|cant|never)[[:space:]]+hand off to writing-plans/) {
            next
        }
        if (line ~ /stay inside the research workflow/) {
            next
        }

        if (line ~ /two execution options/ ||
            line ~ /which approach/ ||
            line ~ /subagent-driven \(recommended\)/ ||
            line ~ /inline execution/ ||
            line ~ /use writing-plans/ ||
            line ~ /hand off to writing-plans/ ||
            line ~ /next (step|skill).*(writing-plans|executing-plans|subagent-driven-development)/ ||
            line ~ /generic planning/ ||
            line ~ /use executing-plans/ ||
            line ~ /use subagent-driven-development/) {
            found = 1
            exit
        }
    }
    END {
        exit found ? 0 : 1
    }
    ' "$output_file"
}

assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  Did not expect to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

assert_count() {
    local output="$1"
    local pattern="$2"
    local expected="$3"
    local test_name="${4:-test}"

    local actual
    actual=$(echo "$output" | grep -c "$pattern" || echo "0")

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $test_name (found $actual instances)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected $expected instances of: $pattern"
        echo "  Found $actual instances"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

assert_order() {
    local output="$1"
    local pattern_a="$2"
    local pattern_b="$3"
    local test_name="${4:-test}"

    local line_a
    line_a=$(echo "$output" | grep -n "$pattern_a" | head -1 | cut -d: -f1)
    local line_b
    line_b=$(echo "$output" | grep -n "$pattern_b" | head -1 | cut -d: -f1)

    if [ -z "$line_a" ]; then
        echo "  [FAIL] $test_name: pattern A not found: $pattern_a"
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
        return 1
    fi

    if [ "$line_a" -lt "$line_b" ]; then
        echo "  [PASS] $test_name (A at line $line_a, B at line $line_b)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected '$pattern_a' before '$pattern_b'"
        echo "  But found A at line $line_a, B at line $line_b"
        return 1
    fi
}

create_test_project() {
    local test_dir
    test_dir=$(mktemp -d)
    echo "$test_dir"
}

cleanup_test_project() {
    local test_dir="$1"
    local exit_code="${2:-0}"
    local test_name="${3:-test}"
    local claude_output="${4:-}"

    if [ -n "${CLAUDE_RESEARCH_INTEGRATION_ARTIFACT_DIR:-}" ] && [ "$exit_code" -ne 0 ] && [ -d "$test_dir" ]; then
        local target="$CLAUDE_RESEARCH_INTEGRATION_ARTIFACT_DIR/$test_name"
        mkdir -p "$target"
        if command -v tar >/dev/null 2>&1; then
            tar -czf "$target/${test_name}-project.tar.gz" -C "$test_dir" .
        else
            cp -a "$test_dir" "$target/project"
        fi
        if [ -n "$claude_output" ] && [ -f "$claude_output" ]; then
            cp "$claude_output" "$target/"
        fi
    fi

    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

create_test_plan() {
    local project_dir="$1"
    local plan_name="${2:-test-plan}"
    local plan_file="$project_dir/docs/superpowers/plans/$plan_name.md"

    mkdir -p "$(dirname "$plan_file")"

    cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Task 1: Create Hello Function

Create a simple hello function that returns "Hello, World!".

**File:** `src/hello.js`

**Implementation:**
```javascript
export function hello() {
  return "Hello, World!";
}
```

**Tests:** Write a test that verifies the function returns the expected string.

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a goodbye function that takes a name and returns a goodbye message.

**File:** `src/goodbye.js`

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Write tests for:
- Default name
- Custom name
- Edge cases (empty string, null)

**Verification:** `npm test`
EOF

    echo "$plan_file"
}

yaml_list_items() {
    local file="$1"
    local key="$2"

    awk -v key="$key" '
    $0 ~ "^" key ":[[:space:]]*$" { in_list = 1; next }
    in_list && $0 ~ /^[^[:space:]]/ { exit }
    in_list && $0 ~ /^[[:space:]]*-[[:space:]]*/ {
        item = $0
        sub(/^[[:space:]]*-[[:space:]]*/, "", item)
        gsub(/^"/, "", item)
        gsub(/"$/, "", item)
        print item
        next
    }
    in_list && $0 ~ /^[[:space:]]*$/ { next }
    in_list { exit }
    ' "$file"
}

yaml_list_equals_exactly() {
    local file="$1"
    local key="$2"
    shift 2

    local expected=("$@")
    local actual=()
    local item
    while IFS= read -r item; do
        actual+=("$item")
    done < <(yaml_list_items "$file" "$key")

    if [ "${#actual[@]}" -ne "${#expected[@]}" ]; then
        return 1
    fi

    local i
    for i in "${!expected[@]}"; do
        if [ "${actual[$i]}" != "${expected[$i]}" ]; then
            return 1
        fi
    done

    return 0
}

yaml_keys_present() {
    local file="$1"
    shift

    local key
    for key in "$@"; do
        if ! grep -Eq "^[[:space:]]*$key:" "$file"; then
            return 1
        fi
    done

    return 0
}

yaml_scalar_value() {
    local file="$1"
    local key="$2"

    awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key ":[[:space:]]*" {
        value = $0
        sub("^[[:space:]]*" key ":[[:space:]]*", "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value ~ /^".*"$/) {
            sub(/^"/, "", value)
            sub(/"$/, "", value)
        }
        print value
        exit
    }
    ' "$file"
}

resolve_repo_path() {
    local project_root="$1"
    local path_value="$2"
    local candidate

    if [ -z "$path_value" ] || [ "$path_value" = "null" ]; then
        return 1
    fi

    if [[ "$path_value" = /* ]]; then
        candidate="$path_value"
    else
        candidate="$project_root/$path_value"
    fi

    local candidate_dir
    candidate_dir="$(dirname "$candidate")"
    if [ ! -d "$candidate_dir" ]; then
        return 1
    fi

    (
        cd "$candidate_dir" >/dev/null 2>&1 || exit 1
        printf '%s/%s\n' "$(pwd -P)" "$(basename "$candidate")"
    )
}

state_path_matches_file() {
    local project_root="$1"
    local state_file="$2"
    local key="$3"
    local expected_file="$4"

    local raw_value
    raw_value="$(yaml_scalar_value "$state_file" "$key")"
    if [ -z "$raw_value" ] || [ "$raw_value" = "null" ]; then
        return 1
    fi

    local resolved_from_state
    local resolved_expected
    resolved_from_state="$(resolve_repo_path "$project_root" "$raw_value")" || return 1
    resolved_expected="$(resolve_repo_path "$project_root" "$expected_file")" || return 1

    if [ ! -f "$resolved_from_state" ] || [ ! -r "$resolved_from_state" ]; then
        return 1
    fi

    [ "$resolved_from_state" = "$resolved_expected" ]
}

export -f run_with_timeout
export -f init_research_artifact_dir
export -f classify_failure_type
export -f run_test_with_capture
export -f run_with_timeout_to_output
export -f run_claude
export -f output_suggests_generic_execution_handoff
export -f assert_contains
export -f assert_not_contains
export -f assert_count
export -f assert_order
export -f create_test_project
export -f cleanup_test_project
export -f create_test_plan
export -f yaml_list_items
export -f yaml_list_equals_exactly
export -f yaml_keys_present
export -f yaml_scalar_value
export -f resolve_repo_path
export -f state_path_matches_file
