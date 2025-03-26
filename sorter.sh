#!/usr/bin/env  bash

# set -xeuo pipefail
declare -A default_dirs=(
  [cpp]="cpp"
  [pdf]="books"
  [txt]="notes"
)

declare -A user_dirs

declare -a found_extensions

load_config() {
  local CONFIG_FILE="$HOME/.config/sorter/sorter.conf"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "No config found, writing template" >&2
    mkdir .config/sorter
    touch "$CONFIG_FILE"
    printf "# Custom directory mappings for filetypes\n# Format: EXTENSION=DIRECTORYNAME\ncpp=cpp\npdf=books\ntxt=notes\nmp3=music\n" >"$CONFIG_FILE"
    return 1
  fi

  while IFS='=' read -r ext dir; do
    if [[ -n "$ext" && ! "$ext" =~ ^# ]]; then
      user_dirs["$ext"]="${dir//[^[:alnum:]_-]/}"
    fi
  done <"$CONFIG_FILE"
}

while getopts 'mp:' OPTION; do
  case $OPTION in
  p)
    if [[ -d "$OPTARG" ]]; then
      cd "$OPTARG"
      echo "Changed directory to $OPTARG"
    else
      echo "Invalid directory: $OPTARG" >&2
      exit 1
    fi
    ;;
  m)
    manual_mode=1
    ;;
  esac
done

find_extensions() {
  shopt -s nullglob
  for file in *.*; do
    local ext="${file##*.}"
    if [[ -n "$ext" && ! " ${found_extensions[@]} " =~ " $ext " ]]; then
      found_extensions+=("$ext")
    fi
  done
  shopt -u nullglob

  if [[ ${#found_extensions[@]} -eq 0 ]]; then
    echo "No files with extensions found." >&2
    return 1
  fi
}

get_target_dir() {
  local ext="$1"

  if [[ -v "user_dirs[$ext]" ]]; then
    echo "${user_dirs[$ext]}"
    return
  fi

  if [[ -v default_dirs[$ext] ]]; then
    echo "${default_dirs[$ext]}"
    return
  fi

  while true; do
    read -rp "Enter directory name for .$ext files? (default: ${ext}_files):" dir
    dir=$(tr -d '[:space:]' <<<"$dir" | tr -cd '[:alnum:]_-')

    if [[ -z "$dir" ]]; then
      dir="${ext}_files"
    fi

    if [[ "$dir" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      echo "$dir"

      user_dirs["$ext"]="$dir"
      return
    else
      echo "Invalid directory name. Use only letters, numbers, underscores, and hyphens."
    fi
  done
}

main() {
  load_config || echo "Edit the configuration file at $HOME/.config/sorter/sorter.conf then run again"
  find_extensions

  for ext in "${found_extensions[@]}"; do
    target=$(get_target_dir "$ext")
    if [[ ! -d "$target" ]]; then
      mkdir -p "$target"
      echo "Created directory: $target"
    fi
    mv -- *."$ext" "$target/" 2>/dev/null && echo "Moved .$ext to $target/"
  done
}

main "$@"
