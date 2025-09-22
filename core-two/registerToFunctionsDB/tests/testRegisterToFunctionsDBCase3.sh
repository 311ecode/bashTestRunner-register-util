#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Test Case 3: Verify documentation file handling
testRegisterToFunctionsDBCase3() {
  # Store initial directory and set up trap for cleanup
  local initial_dir=$(pwd)
  local test_dir=$(mktemp -d -t test-registerToFunctionsDBCase3-XXXXXXXXXX)
  trap 'rm -rf "$test_dir"; cd "$initial_dir"' EXIT

  # Change to test directory
  cd "$test_dir"

  # Create temporary DB file
  local db_file=$(mktemp -t functions_db-XXXXXXXXXX.json)
  echo "DEBUG: Database file set to $db_file"

  # Test 3.1: DOC_FILE with valid relative path
  echo "Running Test Case 3.1: DOC_FILE with valid relative path"
  mkdir -p docs
  touch docs/feature.md
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file DOC_FILE=./docs/feature.md"
  DB_FILE="$db_file" DOC_FILE="./docs/feature.md" . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  local expected_doc_file="$test_dir/docs/feature.md"
  local doc_file_path=$(jq -r '.["registered-functions"][] | select(.name == "avind") | .file.doc_file' "$db_file")
  echo "DEBUG: doc_file_path for avind: $doc_file_path"
  echo "DEBUG: expected_doc_file: $expected_doc_file"
  if [[ $doc_file_path == "$expected_doc_file" ]]; then
    echo "Test Case 3.1 PASSED: DOC_FILE correctly set to $expected_doc_file"
  else
    echo "Test Case 3.1 FAILED: Expected doc_file=$expected_doc_file, got $doc_file_path"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -rf test_script.sh docs
    cd "$initial_dir"
    return 1
  fi

  # Clean up for next test
  rm -rf test_script.sh docs "$db_file"

  # Test 3.2: Default to readme.md when DOC_FILE is unset
  echo "Running Test Case 3.2: Default to readme.md when DOC_FILE is unset"
  touch README.MD # Case-insensitive test
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file (no DOC_FILE)"
  DB_FILE="$db_file" . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  expected_doc_file="$test_dir/README.MD"
  doc_file_path=$(jq -r '.["registered-functions"][] | select(.name == "avind") | .file.doc_file' "$db_file")
  echo "DEBUG: doc_file_path for avind: $doc_file_path"
  echo "DEBUG: expected_doc_file: $expected_doc_file"
  if [[ $doc_file_path == "$expected_doc_file" ]]; then
    echo "Test Case 3.2 PASSED: Default doc_file correctly set to $expected_doc_file"
  else
    echo "Test Case 3.2 FAILED: Expected doc_file=$expected_doc_file, got $doc_file_path"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -f test_script.sh README.MD
    cd "$initial_dir"
    return 1
  fi

  # Clean up for next test
  rm -f test_script.sh README.MD "$db_file"

  # Test 3.3: No doc_file when DOC_FILE unset and no readme.md
  echo "Running Test Case 3.3: No doc_file when DOC_FILE unset and no readme.md"
  testRegisterToFunctionsDBCreateTestScript "test_script.sh"
  echo "DEBUG: Sourcing test_script.sh with DB_FILE=$db_file (no DOC_FILE, no readme.md)"
  DB_FILE="$db_file" . ./test_script.sh
  echo "DEBUG: Sourcing complete"

  doc_file_path=$(jq -r '.["registered-functions"][] | select(.name == "avind") | .file.doc_file' "$db_file")
  echo "DEBUG: doc_file_path for avind: $doc_file_path"
  if [[ $doc_file_path == "null" ]]; then
    echo "Test Case 3.3 PASSED: doc_file correctly set to null"
  else
    echo "Test Case 3.3 FAILED: Expected doc_file=null, got $doc_file_path"
    echo "DEBUG: Database contents:"
    cat "$db_file"
    rm -f test_script.sh
    cd "$initial_dir"
    return 1
  fi

  # Clean up
  rm -f test_script.sh "$db_file"

  # Return to initial directory
  cd "$initial_dir"
  return 0
}
