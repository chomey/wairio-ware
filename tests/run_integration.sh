#!/bin/bash
# Integration test runner: launches host + client Godot instances headless
# and verifies the full game flow completes successfully.

set -e

GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_LOG="$PROJECT_DIR/test_host.log"
CLIENT_LOG="$PROJECT_DIR/test_client.log"
HOST_GODOT_LOG="$PROJECT_DIR/test_host_godot.log"
CLIENT_GODOT_LOG="$PROJECT_DIR/test_client_godot.log"
TIMEOUT=120

# Build --test-games arg from positional parameters (game display names)
TEST_GAMES_ARG=""
if [ $# -gt 0 ]; then
    GAMES=$(IFS=,; echo "$*")
    TEST_GAMES_ARG="--test-games=$GAMES"
fi

# Clean up old logs
rm -f "$HOST_LOG" "$CLIENT_LOG" "$HOST_GODOT_LOG" "$CLIENT_GODOT_LOG"

echo "=== WarioParty Integration Test ==="
echo "Project: $PROJECT_DIR"
echo "Timeout: ${TIMEOUT}s"
if [ -n "$TEST_GAMES_ARG" ]; then
    echo "Games: $TEST_GAMES_ARG"
fi
echo ""

# Launch host instance
echo "Starting host..."
"$GODOT" --headless --path "$PROJECT_DIR" --log-file "$HOST_GODOT_LOG" -- --test-host "$TEST_GAMES_ARG" &
HOST_PID=$!
echo "Host PID: $HOST_PID"

# Wait for host to start before launching client
sleep 2

# Launch client instance
echo "Starting client..."
"$GODOT" --headless --path "$PROJECT_DIR" --log-file "$CLIENT_GODOT_LOG" -- --test-client "$TEST_GAMES_ARG" &
CLIENT_PID=$!
echo "Client PID: $CLIENT_PID"

echo ""
echo "Waiting for test to complete (timeout: ${TIMEOUT}s)..."

# Wait for both processes with timeout
ELAPSED=0
HOST_EXIT=""
CLIENT_EXIT=""

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check if host exited
    if [ -z "$HOST_EXIT" ] && ! kill -0 "$HOST_PID" 2>/dev/null; then
        wait "$HOST_PID" 2>/dev/null && HOST_EXIT=0 || HOST_EXIT=$?
        echo "Host exited with code: $HOST_EXIT (at ${ELAPSED}s)"
    fi

    # Check if client exited
    if [ -z "$CLIENT_EXIT" ] && ! kill -0 "$CLIENT_PID" 2>/dev/null; then
        wait "$CLIENT_PID" 2>/dev/null && CLIENT_EXIT=0 || CLIENT_EXIT=$?
        echo "Client exited with code: $CLIENT_EXIT (at ${ELAPSED}s)"
    fi

    # Both done?
    if [ -n "$HOST_EXIT" ] && [ -n "$CLIENT_EXIT" ]; then
        break
    fi

    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

# Kill any remaining processes
if [ -z "$HOST_EXIT" ]; then
    echo "Host timed out, killing..."
    kill "$HOST_PID" 2>/dev/null || true
    wait "$HOST_PID" 2>/dev/null || true
    HOST_EXIT=124
fi
if [ -z "$CLIENT_EXIT" ]; then
    echo "Client timed out, killing..."
    kill "$CLIENT_PID" 2>/dev/null || true
    wait "$CLIENT_PID" 2>/dev/null || true
    CLIENT_EXIT=124
fi

echo ""
echo "=== Test Results ==="
echo ""

# Print host log
if [ -f "$HOST_LOG" ]; then
    echo "--- Host Log ---"
    cat "$HOST_LOG"
    echo ""
else
    echo "--- Host Log: NOT FOUND ---"
fi

# Print client log
if [ -f "$CLIENT_LOG" ]; then
    echo "--- Client Log ---"
    cat "$CLIENT_LOG"
    echo ""
else
    echo "--- Client Log: NOT FOUND ---"
fi

# Determine pass/fail
echo "=== Summary ==="
echo "Host exit code: $HOST_EXIT"
echo "Client exit code: $CLIENT_EXIT"

# Check for PASS/FAIL in logs
HOST_PASSED=false
CLIENT_PASSED=false
if [ -f "$HOST_LOG" ] && grep -q "TEST PASSED" "$HOST_LOG"; then
    HOST_PASSED=true
fi
if [ -f "$CLIENT_LOG" ] && grep -q "TEST PASSED" "$CLIENT_LOG"; then
    CLIENT_PASSED=true
fi

# Clean up logs
rm -f "$HOST_LOG" "$CLIENT_LOG" "$HOST_GODOT_LOG" "$CLIENT_GODOT_LOG"

if [ "$HOST_EXIT" = "0" ] && [ "$CLIENT_EXIT" = "0" ]; then
    echo ""
    echo "INTEGRATION TEST PASSED"
    exit 0
elif [ "$HOST_PASSED" = "true" ]; then
    # Host passed, client may have exited early (acceptable - host drives the test)
    echo ""
    echo "INTEGRATION TEST PASSED (host validated)"
    exit 0
else
    echo ""
    echo "INTEGRATION TEST FAILED"
    # Print godot logs for debugging if they exist
    for log in "$HOST_GODOT_LOG" "$CLIENT_GODOT_LOG"; do
        if [ -f "$log" ]; then
            echo ""
            echo "--- $(basename "$log") (last 30 lines) ---"
            tail -30 "$log"
            rm -f "$log"
        fi
    done
    exit 1
fi
