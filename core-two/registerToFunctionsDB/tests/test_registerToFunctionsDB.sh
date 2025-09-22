#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Test executor for registerToFunctionsDB test cases
testRegisterToFunctionsDB() {
  local exit_code=0
  local passed_tests=0
  local failed_tests=()

  # Source test case scripts
  echo "DEBUG: Sourcing test case scripts"
  for script in testRegisterToFunctionsDBCase{1,2,3,4}.sh; do
    if [[ ! -f $script ]]; then
      echo "ERROR: $script not found"
      exit 1
    fi
    . ./"$script"
  done
  echo "DEBUG: Test case scripts sourced"

  # Run Test Case 1
  echo "Executing Test Case 1"
  if testRegisterToFunctionsDBCase1; then
    echo "Test Case 1 completed successfully"
    ((passed_tests++))
  else
    echo "Test Case 1 failed"
    failed_tests+=("Test Case 1")
    exit_code=1
  fi

  # Run Test Case 2
  echo "Executing Test Case 2"
  if testRegisterToFunctionsDBCase2; then
    echo "Test Case 2 completed successfully"
    ((passed_tests++))
  else
    echo "Test Case 2 failed"
    failed_tests+=("Test Case 2")
    exit_code=1
  fi

  # Run Test Case 3
  echo "Executing Test Case 3"
  if testRegisterToFunctionsDBCase3; then
    echo "Test Case 3 completed successfully"
    ((passed_tests++))
  else
    echo "Test Case 3 failed"
    failed_tests+=("Test Case 3")
    exit_code=1
  fi

  # Run Test Case 4 (NO_README functionality)
  echo "Executing Test Case 4"
  if testRegisterToFunctionsDBCase4; then
    echo "Test Case 4 completed successfully"
    ((passed_tests++))
  else
    echo "Test Case 4 failed"
    failed_tests+=("Test Case 4")
    exit_code=1
  fi

  # Print test summary
  echo "Test Summary: $passed_tests/4 tests passed"
  if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "Failed Tests: ${failed_tests[*]}"
  fi

  # Return overall exit code
  return $exit_code
}

# Run the test executor
# testRegisterToFunctionsDB
