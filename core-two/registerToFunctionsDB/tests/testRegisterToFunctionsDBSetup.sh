#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Function to create a test script with avind and helloworld functions
testRegisterToFunctionsDBCreateTestScript() {
  local dest_file="$1"
  echo "DEBUG: Creating test script at $dest_file"
  cat >"$dest_file" <<EOF
#!/bin/bash

avind() {
  echo "Avind function"
}

helloworld() {
  echo "Hello, World!"
}

registerToFunctionsDB
EOF
  chmod +x "$dest_file"
  echo "DEBUG: Test script contents:"
  cat "$dest_file"
}
