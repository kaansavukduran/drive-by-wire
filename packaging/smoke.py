"""Headless start-and-quit smoke test for an exported game binary.

  python3 packaging/smoke.py <binary> [extra args...]

Runs `<binary> --headless --quit-after 300` (frames) and fails on a non-zero
exit code, a timeout, or GDScript errors in the output. This proves the binary
starts, loads its embedded PCK and runs the main scene for a few seconds
without a display. It does not prove rendering or input.
"""
import subprocess
import sys

BAD = ("SCRIPT ERROR", "Parse Error", "Failed to load script", "Couldn't load project data")

binary, *extra = sys.argv[1:]
cmd = [binary, "--headless", "--quit-after", "300", *extra]
print("smoke:", " ".join(cmd), flush=True)
try:
    run = subprocess.run(cmd, capture_output=True, text=True, timeout=120, errors="replace")
except subprocess.TimeoutExpired:
    raise SystemExit("smoke FAILED: timed out")
output = run.stdout + run.stderr
print(output[-4000:])
bad = [line for line in output.splitlines() if any(marker in line for marker in BAD)]
if run.returncode != 0 or bad:
    raise SystemExit(f"smoke FAILED: exit {run.returncode}; {bad[:5]}")
print(f"smoke PASS: exit 0, no script errors ({binary})")
