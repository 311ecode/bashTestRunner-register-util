#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Test Case 2: Verify no duplicates are added from a second script
testRegisterToFunctionsDBCase2() {
  # Store initial directory and set up trap for cleanup
  local initial_dir=$(pwd)
  local test_dir=$(mktemp -d -t test-registerToFunctionsDBCase2-XXXXXXXXXX)
  trap 'rm -rf "$test_dir"; cd "$initial_dir"' EXIT

  # Change to test directory
  cd "$test_dir"

  # Create temporary DB file
  local db_file=$(mktemp -t functions_db-XXXXXXXXXX.json)
  echo "DEBUG: Database file set to $db_file"

  # Set up first test script and register functions
  echo "Running Test Case 2: Registering functions from test_script.sh"
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file"
  DB_FILE="$db_file" . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  # Verify initial registration (to ensure setup is correct)
  local avind_count=$(jq '[.["registered-functions"][] | select(.name == "avind")] | length' "$db_file")
  local helloworld_count=$(jq '[.["registered-functions"][] | select(.name == "helloworld")] | length' "$db_file")
  if [[ $avind_count -ne 1 || $helloworld_count -ne 1 ]]; then
    echo "Test Case 2 FAILED: Initial registration failed, expected 1 avind and 1 helloworld, got avind_count=$avind_count, helloworld_count=$helloworld_count"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -f test_script.sh
    cd "$initial_dir"
    return 1
  fi

  # Create and source second test script
  echo "DEBUG: Creating and sourcing test_script2.sh"
  testRegisterToFunctionsDBCreateTestScript "test_script2.sh"
  echo "DEBUG: Sourcing test_script2.sh with DB_FILE=$db_file"
  DB_FILE="$db_file" . ./test_script2.sh
  echo "DEBUG: Sourcing complete"

  # Dump database contents for debugging
  echo "DEBUG: Database contents after Test Case 2:"
  cat "$db_file"

  # Verify that the database still contains only one entry per function
  avind_count=$(jq '[.["registered-functions"][] | select(.name == "avind")] | length' "$db_file")
  helloworld_count=$(jq '[.["registered-functions"][] | select(.name == "helloworld")] | length' "$db_file")
  echo "DEBUG: avind_count: $avind_count"
  echo "DEBUG: helloworld_count: $helloworld_count"

  # Check that the entries correspond to the first script
  local avind_path=$(jq -r '.["registered-functions"][] | select(.name == "avind") | .file.path' "$db_file")
  local helloworld_path=$(jq -r '.["registered-functions"][] | select(.name == "helloworld") | .file.path' "$db_file")
  local expected_path="$test_dir/test_script.sh"
  echo "DEBUG: avind_path: $avind_path"
  echo "DEBUG: helloworld_path: $helloworld_path"
  echo "DEBUG: expected_path: $expected_path"

  if [[ $avind_count -eq 1 && $helloworld_count -eq 1 && $avind_path == "$expected_path" && $helloworld_path == "$expected_path" ]]; then
    echo "Test Case 2 PASSED: No duplicates added, entries remain from test_script.sh"
  else
    echo "Test Case 2 FAILED: Expected 1 avind and 1 helloworld from test_script.sh, got avind_count=$avind_count, helloworld_count=$helloworld_count, avind_path=$avind_path, helloworld_path=$helloworld_path"
    echo "DEBUG: Database contents (repeated for clarity):"
    cat "$db_file"
    rm -f test_script.sh test_script2.sh
    cd "$initial_dir"
    return 1
  fi

  # Clean up
  rm -f test_script.sh test_script2.sh
  rm -f "$db_file"

  # Return to initial directory
  cd "$initial_dir"
  return 0
}
