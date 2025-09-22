#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
resolveCallerAndSetup() {
  # Allow overriding the database file location via environment variable
  local DB_FILE="${DB_FILE:-/tmp/bash_functions_db.json}"

  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: DB_FILE set to $DB_FILE"
  fi

  # Skip if called directly from bash (no script file)
  if [[ $0 == "bash" || $0 == "-bash" || $0 == "/bin/bash" ]]; then
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Called from interactive shell, exiting"
    fi
    return 0
  fi

  # Find the calling script
  local caller_file
  caller_file=$(caller 0 | awk '{print $3}')

  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Caller command output: $(caller 0)"
    echo "DEBUG: Initial caller_file: $caller_file"
  fi

  # If caller doesn't provide the file path, try BASH_SOURCE
  if [[ -z $caller_file || $caller_file == "main" ]]; then
    caller_file="${BASH_SOURCE[1]}"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Using BASH_SOURCE[1]: $caller_file"
    fi
  fi

  # If we still don't have a file path, use the current script
  if [[ -z $caller_file ]]; then
    caller_file="${BASH_SOURCE[0]}"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Using BASH_SOURCE[0]: $caller_file"
    fi
  fi

  # Resolve to absolute path if it's a file
  if [[ -f $caller_file ]]; then
    caller_file=$(readlink -f "$caller_file")
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Resolved caller_file to absolute path: $caller_file"
    fi
  else
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: No valid file found for caller. Exiting."
    fi
    return 0
  fi

  # Determine the documentation file
  local doc_file=""
  local caller_dir=$(dirname "$caller_file")

  if [[ -z $NO_README ]]; then
    if [[ -n $DOC_FILE ]]; then
      if [[ $DOC_FILE =~ ^\./ || $DOC_FILE =~ ^\../ ]]; then
        doc_file=$(realpath -m "$caller_dir/$DOC_FILE")
        if is_debug_mode_registerToFunctionsDB; then
          echo "DEBUG: DOC_FILE set to $DOC_FILE, resolved to $doc_file"
        fi
        if [[ ! -f "$caller_dir/$DOC_FILE" ]]; then
          if is_debug_mode_registerToFunctionsDB; then
            echo "DEBUG: Warning: DOC_FILE $DOC_FILE does not exist"
          fi
          doc_file=""
        fi
      else
        if is_debug_mode_registerToFunctionsDB; then
          echo "DEBUG: Warning: DOC_FILE must start with ./ or ../, ignoring $DOC_FILE"
        fi
      fi
    else
      doc_file=$(find "$caller_dir" -maxdepth 1 -type f -iname "readme.md" | head -n 1)
      if [[ -n $doc_file ]]; then
        doc_file=$(realpath -m "$doc_file")
        if is_debug_mode_registerToFunctionsDB; then
          echo "DEBUG: No DOC_FILE set, found default $doc_file"
        fi
      else
        if is_debug_mode_registerToFunctionsDB; then
          echo "DEBUG: No DOC_FILE set and no readme.md found"
        fi
      fi
    fi
  else
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: NO_README is set, skipping documentation file lookup"
    fi
  fi

  # Initialize database if it doesn't exist
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Ensuring DB_FILE exists"
  fi
  touchPlus "$DB_FILE" 2>/dev/null
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: DB_FILE created or touched"
  fi
  if [[ ! -s $DB_FILE ]]; then
    echo '{"registered-functions":[]}' >"$DB_FILE"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: DB_FILE is empty, initializing with empty JSON"
    fi
  else
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: DB_FILE exists, contents:"
      batcat --paging=never "$DB_FILE" 2>/dev/null || echo "DEBUG: batcat failed, DB contents: $(cat "$DB_FILE")"
    fi
  fi

  # Return the resolved values
  echo "$caller_file:$doc_file:$DB_FILE"
}
