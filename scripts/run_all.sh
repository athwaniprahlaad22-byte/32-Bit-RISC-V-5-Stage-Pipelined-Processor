#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run_all.sh - compile and run every testbench with Icarus Verilog
#
# Usage (from the repo root):
#   ./scripts/run_all.sh                    # all tests
#   ./scripts/run_all.sh tb_cpu_branch      # one test
#   VCD=1 ./scripts/run_all.sh              # also dump waveforms to build/
#
# Logs go to results/<tb>.log.
# ---------------------------------------------------------------------------
set -u
cd "$(dirname "$0")/.."

mkdir -p build results

if [ $# -gt 0 ]; then
  TESTS=("$@")
else
  TESTS=()
  for f in tb/tb_*.v; do TESTS+=("$(basename "$f" .v)"); done
fi

passed=0
failed=()
for tb in "${TESTS[@]}"; do
  sim="build/${tb}.vvp"
  log="results/${tb}.log"
  if ! iverilog -g2012 -Wall -I rtl -I tb -o "$sim" rtl/*.v "tb/${tb}.v"; then
    failed+=("${tb} (compile)")
    continue
  fi
  args=("$sim")
  [ "${VCD:-0}" = "1" ] && args+=("+vcd=build/${tb}.vcd")
  vvp "${args[@]}" | grep -v '^VCD info' | tee "$log"
  if grep -q '^TEST PASSED' "$log"; then passed=$((passed + 1)); else failed+=("$tb"); fi
  echo
done

echo "=========================================="
echo "  ${passed} passed, ${#failed[@]} failed"
for f in "${failed[@]}"; do echo "  FAILED: $f"; done
echo "=========================================="
[ ${#failed[@]} -eq 0 ]
