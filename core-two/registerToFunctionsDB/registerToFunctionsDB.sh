#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

# Function to check DEBUG variable
is_debug_mode_registerToFunctionsDB() {
    [ -n "$DEBUG" ] && [ "${DEBUG,,}" != "0" ] && [ "${DEBUG,,}" != "false" ]
}

# Function to automatically register functions from the calling script
registerToFunctionsDB() {
  # Allow overriding the database file location via environment variable
  local DB_FILE="${DB_FILE:-/tmp/bash_functions_db.json}"
  
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: DB_FILE set to $DB_FILE"
  fi

  # Skip if called directly from bash (no script file)
  if [[ "$0" == "bash" || "$0" == "-bash" || "$0" == "/bin/bash" ]]; then
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
  if [[ -z "$caller_file" || "$caller_file" == "main" ]]; then
    caller_file="${BASH_SOURCE[1]}"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Using BASH_SOURCE[1]: $caller_file"
    fi
  fi

  # If we still don't have a file path, use the current script
  if [[ -z "$caller_file" ]]; then
    caller_file="${BASH_SOURCE[0]}"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Using BASH_SOURCE[0]: $caller_file"
    fi
  fi

  # Resolve to absolute path if it's a file
  if [[ -f "$caller_file" ]]; then
    caller_file=$(readlink -f "$caller_file")
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Resolved caller_file to absolute path: $caller_file"
    fi
  else
    # Not a file, likely called from interactive shell
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: No valid file found for caller. Exiting."
    fi
    return 0
  fi

  # Determine the documentation file
  local doc_file=""
  local caller_dir=$(dirname "$caller_file")
  
  # Only look for documentation if NO_README is not set
  if [[ -z "$NO_README" ]]; then
    if [[ -n "$DOC_FILE" ]]; then
      # Check if DOC_FILE starts with ./ or ../
      if [[ "$DOC_FILE" =~ ^\./ || "$DOC_FILE" =~ ^\../ ]]; then
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
      # Look for readme.md (case-insensitive) in the same directory
      doc_file=$(find "$caller_dir" -maxdepth 1 -type f -iname "readme.md" | head -n 1)
      if [[ -n "$doc_file" ]]; then
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
  if [[ ! -s "$DB_FILE" ]]; then
    echo '{"registered-functions":[]}' > "$DB_FILE"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: DB_FILE is empty, initializing with empty JSON"
    fi
  else
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: DB_FILE exists, contents:"
      batcat --paging=never "$DB_FILE" 2>/dev/null || echo "DEBUG: batcat failed, DB contents: $(cat "$DB_FILE")"
    fi
  fi

  # Get functions from the calling script using the existing getBashElements
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Running getBashElements on $caller_file"
  fi
  local functions
  functions=$(getBashElements "$caller_file")
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Raw getBashElements output: $functions"
  fi

  # Filter out system variables and non-function names
  functions=$(echo "$functions" | grep -E '^[a-zA-Z_][a-zA-Z0-9_]+$' | grep -v -E '^(LINES|COLUMNS|BASH_|COMP_|DIRSTACK|GROUPS|PIPESTATUS|FUNCNAME|HOSTNAME)$')
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Filtered functions: $functions"
  fi

  # Skip if no functions found
  if [[ -z "$functions" ]]; then
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: No valid functions found, exiting"
    fi
    return 0
  fi

  # Get the file info
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Collecting file metadata"
  fi
  local file_info
  file_info=$(jq -n \
    --arg path "$caller_file" \
    --arg last_modified "$(date -r "$caller_file" "+%Y-%m-%d %H:%M:%S")" \
    --arg size "$(stat -c%s "$caller_file")" \
    --arg doc_file "$doc_file" \
    '{path: $path, last_modified: $last_modified, size: $size, doc_file: ($doc_file | if . == "" then null else . end)}')
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: File info JSON: $file_info"
  fi

  # Get existing function names from the database
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Reading existing functions from DB"
  fi
  local existing_functions
  existing_functions=$(jq -r '.["registered-functions"][].name' "$DB_FILE" 2>/dev/null || echo "")
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Existing functions in DB: $existing_functions"
  fi

  # Build JSON array directly
  local entries="["
  local separator=""
  local added_count=0

  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: Processing function names"
  fi
  while IFS= read -r func_name; do
    # Skip empty lines and likely non-function entries
    [[ -z "$func_name" || "$func_name" == *"{"* || "$func_name" == *"}"* || "$func_name" == *'"'* ]] && {
      if is_debug_mode_registerToFunctionsDB; then
        echo "DEBUG: Skipping invalid function name: $func_name"
      fi
      continue
    }

    # Skip if function already exists in the database
    if echo "$existing_functions" | grep -qx "$func_name"; then
      if is_debug_mode_registerToFunctionsDB; then
        echo "DEBUG: Function $func_name already exists, skipping"
      fi
      continue
    fi

    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Adding function $func_name to entries"
    fi
    entries+="$separator"
    entries+=$(jq -n \
      --arg name "$func_name" \
      --argjson file "$file_info" \
      '{name: $name, file: $file}')
    separator=","
    ((added_count++))
  done <<< "$functions"

  entries+="]"
  if is_debug_mode_registerToFunctionsDB; then
    echo "DEBUG: JSON entries to add: $entries"
    echo "DEBUG: Number of functions to add: $added_count"
  fi

  # Only update if we have new functions to add
  if [[ $added_count -gt 0 ]]; then
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Updating database with new functions"
    fi
    local TEMP_JSON
    TEMP_JSON=$(mktemp)
    jq --argjson new "$entries" '
      .["registered-functions"] = (
        .["registered-functions"] + $new
      )
    ' "$DB_FILE" > "$TEMP_JSON" && mv "$TEMP_JSON" "$DB_FILE"
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: Database updated, new contents:"
      batcat --paging=never "$DB_FILE" 2>/dev/null || echo "DEBUG: batcat failed, DB contents: $(cat "$DB_FILE")"
    fi
  else
    if is_debug_mode_registerToFunctionsDB; then
      echo "DEBUG: No new functions to add, skipping database update"
    fi
  fi
}
export -f registerToFunctionsDB
export -f is_debug_mode_registerToFunctionsDB
# Simply call registerToFunctionsDB from any script to register all functions
registerToFunctionsDB

if is_debug_mode_registerToFunctionsDB; then
  echo "DEBUG: Final database contents:"
  batcat --paging=never /tmp/bash_functions_db.json 2>/dev/null || echo "DEBUG: batcat failed, DB contents: $(cat /tmp/bash_functions_db.json)"
fi
