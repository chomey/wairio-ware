#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

for ((i=1; i<=$1; i++)); do
  echo ""
  echo "==============================="
  echo "  Iteration $i / $1  ($(date '+%H:%M:%S'))"
  echo "==============================="

  start_ts=$(date +%s)

  # Stream output live via tee while capturing to file for completion check
  claude -p "$(cat PROMPT.md)" --output-format text 2>&1 | tee "$TMPFILE" || true

  end_ts=$(date +%s)
  elapsed=$(( end_ts - start_ts ))
  echo ""
  echo "--- End of iteration $i (${elapsed}s) ---"

  if grep -q '<promise>COMPLETE</promise>' "$TMPFILE"; then
    echo "All tasks complete after $i iterations."
    exit 0
  fi
done

echo "Reached max iterations ($1)"
exit 1

