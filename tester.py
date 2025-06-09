import subprocess
import os

SAMPLES_DIR = "samples"
PROINF_EXEC = ["racket", "proinf.rkt", "-t", "-f"]

def run_test(script_path):
    result = subprocess.run(
        PROINF_EXEC + [script_path],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()

def main():
    passed = 0
    failed = 0

    for filename in os.listdir(SAMPLES_DIR):
        if filename.endswith(".txt"):
            continue
        script_path = os.path.join(SAMPLES_DIR, filename)
        expected_path = script_path + ".txt"
        if not os.path.exists(expected_path):
            print(f"Skipping {filename} (no expected output file)")
            continue

        actual_output = run_test(script_path)
        with open(expected_path, "r") as f:
            expected_output = f.read().strip()

        if actual_output == expected_output:
            print(f"[PASS] {filename}")
            passed += 1
        else:
            print(f"[FAIL] {filename}")
            print("---- Expected ----")
            print(expected_output)
            print("---- Actual ----")
            print(actual_output)
            failed += 1

    print(f"\nSummary: {passed} passed, {failed} failed")

if __name__ == "__main__":
    main()
