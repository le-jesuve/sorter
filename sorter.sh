#!/usr/bin/env  bash

while getopts 'mp:' OPTION; do
  case $OPTION in
  p)
    if [[ -d "$OPTARG" ]]; then
      cd "$OPTARG"
      echo "Changed directory to $OPTARG"
    else
      echo "Invalid directory: $OPTARG"
      exit 1
    fi
    ;;
  m)
    manual_mode=1
    ;;
  esac
done

mapfile -t ext < <(
  for file in *; do
    if [[ "$file" =~ \. ]]; then
      printf "%s\n" "${file##*.}"
    fi
  done | sort -u
)

if [[ -z "$ext" ]]; then
  echo "Nothing to do."
  exit 1
fi

getdir() {
  for i in "${!ext[@]}"; do
    echo "Directory name for ${ext[i]}"
    read -r dirname[i]
    dirname[i]=$(echo "${dirname[i]}" | tr -d '[:space:]' | tr -cd '[:alnum:]_+-')
    if [[ -z "${dirname[i]}" ]]; then
      echo "Invalid directory name. Please try again."
      exit 1
    fi
  done
}

if ((manual_mode)); then
  getdir
  for i in "${!ext[@]}"; do
    origin=".${ext[i]}"
    target="${dirname[i]}"

    if [[ -z $(find . -type d -name "$target" 2>/dev/null) ]]; then
      mkdir -p "$target"
      echo "Directory '$target' created."
    fi

    mv *"$origin" "$target"
    echo "$origin moved to $target"
  done
else
  for i in "${!ext[@]}"; do
    origin="${ext[i]}"

    case $origin in
    cpp)
      target="cpp"
      if [[ -z $(find . -type d -name "$target" 2>/dev/null) ]]; then
        mkdir -p "$target"
        echo "Directory '$target' created."
      fi
      mv *".$origin" "$target"
      echo ".$origin moved to $target"
      ;;
    pdf)
      target="books"
      if [[ -z $(find . -type d -name "$target" 2>/dev/null) ]]; then
        mkdir -p "$target"
        echo "Directory '$target' created."
      fi
      mv *".$origin" "$target"
      echo ".$origin moved to $target"
      ;;
    txt)
      target="notes"
      if [[ -z $(find . -type d -name "$target" 2>/dev/null) ]]; then
        mkdir -p "$target"
        echo "Directory '$target' created."
      fi
      mv *".$origin" "$target"
      echo ".$origin moved to $target"
      ;;
    esac
  done
fi
