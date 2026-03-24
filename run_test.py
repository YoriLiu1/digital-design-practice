#!/usr/bin/env python3
"""
Test runner for async FIFO simulation
Compatible with Python 3.6+
Location: /home/yori/digital-design-practice/run_test.py
"""

import subprocess
import os
import sys

def run_cmd(cmd):
    """Run command and return result (compatible with Python 3.6)"""
    process = subprocess.Popen(
        cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )
    stdout, stderr = process.communicate()
    return process.returncode, stdout, stderr

def run_async_fifo_test():
    """Run async FIFO simulation and check results"""
    
    # Change to project directory
    project_dir = "/home/yori/digital-design-practice"
    os.chdir(project_dir)
    
    print("=" * 60)
    print("Async FIFO Test Runner")
    print("=" * 60)
    print(f"Working directory: {os.getcwd()}")
    print()
    
    # Step 1: Clean previous simulation
    print("[1/3] Cleaning previous simulation...")
    returncode, stdout, stderr = run_cmd("make MODULE=async_fifo clean")
    print("      Done.")
    
    # Step 2: Compile
    print("[2/3] Compiling async FIFO...")
    returncode, stdout, stderr = run_cmd("make MODULE=async_fifo cmp")
    
    if returncode != 0:
        print("COMPILATION FAILED!")
        print("\n--- Compilation Error Output ---")
        print(stderr)
        return False
    print("      Compilation successful.")
    
    # Step 3: Run simulation
    print("[3/3] Running simulation...")
    returncode, stdout, stderr = run_cmd("make MODULE=async_fifo sim")
    
    # Check if simulation passed
    if "All tests completed" in stdout:
        print("Simulation PASSED!")
        return True
    else:
        print("Simulation FAILED!")
        print("\n--- Simulation Output (last 50 lines) ---")
        lines = stdout.split('\n')
        for line in lines[-50:]:
            print(line)
        return False

def main():
    """Main function"""
    success = run_async_fifo_test()
    
    print()
    print("=" * 60)
    if success:
        print("RESULT: Async FIFO test PASSED!")
    else:
        print("RESULT: Async FIFO test FAILED!")
    print("=" * 60)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
