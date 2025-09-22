#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Test Case 1: Verify functions are registered in the JSON database
testRegisterToFunctionsDBCase1() {
  # Store initial directory and set up trap for cleanup
  local initial_dir=$(pwd)
  local test_dir=$(mktemp -d -t test-registerToFunctionsDBCase1-XXXXXXXXXX)
  trap 'rm -rf "$test_dir"; cd "$initial_dir"' EXIT

  # Change to test directory
  cd "$test_dir"

  # Create temporary DB file
  local db_file=$(mktemp -t functions_db-XXXXXXXXXX.json)
  echo "DEBUG: Database file set to $db_file"

  # Test Case 1: Register functions from test_script.sh
  echo "Running Test Case 1: Registering functions from test_script.sh"

  # Set up test environment
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"

  # Source the test script with DB_FILE set
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file"
  DB_FILE="$db_file" . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  # Check if the database file exists
  if [[ ! -f $db_file ]]; then
    echo "Test Case 1 FAILED: Database file $db_file was not created"
    rm -f test_script.sh
    cd "$initial_dir"
    return 1
  fi

  # Check if the database file is valid JSON
  if ! jq . "$db_file" >/dev/null 2>&1; then
    echo "Test Case 1 FAILED: Database file $db_file is not valid JSON"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -f test_script.sh
    cd "$initial_dir"
    return 1
  fi

  # Dump database contents for debugging
  echo "DEBUG: Database contents after Test Case 1:"
  cat "$db_file"

  # Verify that both functions are registered
  local avind_count=$(jq '[.["registered-functions"][] | select(.name == "avind")] | length' "$db_file")
  local helloworld_count=$(jq '[.["registered-functions"][] | select(.name == "helloworld")] | length' "$db_file")
  echo "DEBUG: avind_count: $avind_count"
  echo "DEBUG: helloworld_count: $helloworld_count"

  if [[ $avind_count -eq 1 && $helloworld_count -eq 1 ]]; then
    echo "Test Case 1 PASSED: Both avind and helloworld functions registered correctly"
  else
    echo "Test Case 1 FAILED: Expected 1 avind and 1 helloworld in $db_file, got avind_count=$avind_count, helloworld_count=$helloworld_count"
    echo "DEBUG: Database contents (repeated for clarity):"
    cat "$db_file"
    rm -f test_script.sh
    cd "$initial_dir"
    return 1
  fi

  # Clean up
  rm -f test_script.sh
  rm -f "$db_file"

  # Return to initial directory
  cd "$initial_dir"
  return 0
}
