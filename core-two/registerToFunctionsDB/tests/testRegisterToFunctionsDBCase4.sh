#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Test Case 4: Verify NO_README environment variable functionality
testRegisterToFunctionsDBCase4() {
  # Store initial directory and set up trap for cleanup
  local initial_dir=$(pwd)
  local test_dir=$(mktemp -d -t test-registerToFunctionsDBCase4-XXXXXXXXXX)
  trap 'rm -rf "$test_dir"; cd "$initial_dir"' EXIT

  # Change to test directory
  cd "$test_dir"

  # Create temporary DB file
  local db_file=$(mktemp -t functions_db-XXXXXXXXXX.json)
  echo "DEBUG: Database file set to $db_file"

  # Test 4.1: With readme.md but NO_README set
  echo "Running Test Case 4.1: With readme.md but NO_README set"

  # Create a readme file
  echo "# Test Readme" >README.md

  # Create test script
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"

  # Run with NO_README set
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file and NO_README=1"
  DB_FILE="$db_file" NO_README=1 . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  # Verify that doc_file is null (not set)
  local doc_file_path=$(jq -r '.["registered-functions"][] | select(.name == "avind") | .file.doc_file' "$db_file")
  echo "DEBUG: doc_file_path for avind: $doc_file_path"

  if [[ $doc_file_path == "null" ]]; then
    echo "Test Case 4.1 PASSED: doc_file correctly set to null when NO_README is set"
  else
    echo "Test Case 4.1 FAILED: Expected doc_file=null, got $doc_file_path"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -f test_script.sh README.md
    cd "$initial_dir"
    return 1
  fi

  # Clean up for next test
  rm -rf test_script.sh README.md "$db_file"

  # Test 4.2: With DOC_FILE set but NO_README is also set
  echo "Running Test Case 4.2: With DOC_FILE set but NO_README also set"

  # Create a documentation file
  mkdir -p docs
  echo "# Test Documentation" >docs/feature.md

  # Create test script
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"

  # Run with NO_README set but DOC_FILE also specified
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file, DOC_FILE=./docs/feature.md, and NO_README=1"
  DB_FILE="$db_file" DOC_FILE="./docs/feature.md" NO_README=1 . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  # Verify that doc_file is null (NO_README should take precedence)
  doc_file_path=$(jq -r '.["registered-functions"][] | select(.name == "avind") | .file.doc_file' "$db_file")
  echo "DEBUG: doc_file_path for avind: $doc_file_path"

  if [[ $doc_file_path == "null" ]]; then
    echo "Test Case 4.2 PASSED: doc_file correctly set to null when NO_README is set, even when DOC_FILE is specified"
  else
    echo "Test Case 4.2 FAILED: Expected doc_file=null, got $doc_file_path"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -rf test_script.sh docs
    cd "$initial_dir"
    return 1
  fi

  # Clean up
  rm -rf test_script.sh docs "$db_file"

  # Return to initial directory
  cd "$initial_dir"
  return 0
}
