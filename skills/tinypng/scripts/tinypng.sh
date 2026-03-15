#!/bin/sh

set -eu

API_URL="https://api.tinify.com/shrink"

usage() {
  cat <<'EOF'
Usage:
  tinypng.sh --input <file> [--output <file>] [--width <n>] [--height <n>] [--convert <webp|avif|jpeg|png>] [--preserve <copyright,creation,location>]

Examples:
  tinypng.sh --input ./hero.png
  tinypng.sh --input ./hero.png --width 128
  tinypng.sh --input ./hero.png --width 128 --height 128
  tinypng.sh --input ./hero.png --convert webp
  tinypng.sh --input ./photo.jpg --preserve creation,location
EOF
}

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR:-}" ]; then
    rm -rf "$TMP_DIR"
  fi
}

validate_positive_integer() {
  value="$1"
  name="$2"
  case "$value" in
    ''|*[!0-9]*)
      fail "$name must be a positive integer."
      ;;
    0)
      fail "$name must be greater than zero."
      ;;
  esac
}

trim_spaces() {
  value="$1"
  value=$(printf '%s' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  printf '%s' "$value"
}

default_output_path() {
  input_path="$1"
  convert_format="$2"

  dir_name=$(dirname "$input_path")
  file_name=$(basename "$input_path")
  base_name=${file_name%.*}

  if [ "$base_name" = "$file_name" ]; then
    current_ext=""
  else
    current_ext=.${file_name##*.}
  fi

  case "$convert_format" in
    webp) target_ext=".webp" ;;
    avif) target_ext=".avif" ;;
    jpeg) target_ext=".jpg" ;;
    png) target_ext=".png" ;;
    '') target_ext="$current_ext" ;;
    *) fail "Unsupported convert format: $convert_format" ;;
  esac

  printf '%s/%s.tinypng%s\n' "$dir_name" "$base_name" "$target_ext"
}

header_value() {
  header_file="$1"
  header_name="$2"
  awk -v wanted="$header_name" '
    tolower($0) ~ ("^" tolower(wanted) ":") {
      sub(/\r$/, "", $0)
      sub(/^[^:]+:[[:space:]]*/, "", $0)
      print $0
      exit
    }
  ' "$header_file"
}

print_error_body() {
  body_file="$1"
  if [ -s "$body_file" ]; then
    printf 'Response body:\n' >&2
    cat "$body_file" >&2
    printf '\n' >&2
  fi
}

INPUT=""
OUTPUT=""
WIDTH=""
HEIGHT=""
CONVERT=""
PRESERVE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      [ "$#" -ge 2 ] || fail "Missing value for --input."
      INPUT="$2"
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || fail "Missing value for --output."
      OUTPUT="$2"
      shift 2
      ;;
    --width)
      [ "$#" -ge 2 ] || fail "Missing value for --width."
      WIDTH="$2"
      shift 2
      ;;
    --height)
      [ "$#" -ge 2 ] || fail "Missing value for --height."
      HEIGHT="$2"
      shift 2
      ;;
    --convert)
      [ "$#" -ge 2 ] || fail "Missing value for --convert."
      CONVERT="$2"
      shift 2
      ;;
    --preserve)
      [ "$#" -ge 2 ] || fail "Missing value for --preserve."
      PRESERVE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

command -v curl >/dev/null 2>&1 || fail "curl is required."
[ -n "${TINYPNG_API_KEY:-}" ] || fail "TINYPNG_API_KEY is not set."
[ -n "$INPUT" ] || fail "The --input argument is required."
[ -f "$INPUT" ] || fail "Input file does not exist: $INPUT"

if [ -n "$WIDTH" ]; then
  validate_positive_integer "$WIDTH" "--width"
fi

if [ -n "$HEIGHT" ]; then
  validate_positive_integer "$HEIGHT" "--height"
fi

case "$CONVERT" in
  ''|webp|avif|jpeg|png)
    ;;
  *)
    fail "Unsupported convert format: $CONVERT"
    ;;
esac

PRESERVE_JSON=""
if [ -n "$PRESERVE" ]; then
  OLD_IFS=${IFS}
  IFS=,
  set -f
  preserve_items=""
  first_item=1
  for raw_item in $PRESERVE; do
    item=$(trim_spaces "$raw_item")
    case "$item" in
      copyright|creation|location)
        ;;
      *)
        IFS=${OLD_IFS}
        set +f
        fail "Unsupported preserve value: $item"
        ;;
    esac

    if [ $first_item -eq 1 ]; then
      preserve_items="\"$item\""
      first_item=0
    else
      preserve_items="$preserve_items,\"$item\""
    fi
  done
  set +f
  IFS=${OLD_IFS}
  [ -n "$preserve_items" ] || fail "The --preserve value must not be empty."
  PRESERVE_JSON="\"preserve\":[$preserve_items]"
fi

if [ -z "$OUTPUT" ]; then
  OUTPUT=$(default_output_path "$INPUT" "$CONVERT")
fi

[ "$OUTPUT" != "$INPUT" ] || fail "Refusing to overwrite the input file. Provide a different --output path."

OUTPUT_DIR=$(dirname "$OUTPUT")
[ -d "$OUTPUT_DIR" ] || fail "Output directory does not exist: $OUTPUT_DIR"

RESIZE_JSON=""
if [ -n "$WIDTH" ] && [ -n "$HEIGHT" ]; then
  RESIZE_JSON="\"resize\":{\"method\":\"fit\",\"width\":$WIDTH,\"height\":$HEIGHT}"
elif [ -n "$WIDTH" ]; then
  RESIZE_JSON="\"resize\":{\"method\":\"scale\",\"width\":$WIDTH}"
elif [ -n "$HEIGHT" ]; then
  RESIZE_JSON="\"resize\":{\"method\":\"scale\",\"height\":$HEIGHT}"
fi

CONVERT_JSON=""
if [ -n "$CONVERT" ]; then
  case "$CONVERT" in
    webp) convert_type="image/webp" ;;
    avif) convert_type="image/avif" ;;
    jpeg) convert_type="image/jpeg" ;;
    png) convert_type="image/png" ;;
    *) fail "Unsupported convert format: $CONVERT" ;;
  esac
  CONVERT_JSON="\"convert\":{\"type\":\"$convert_type\"}"
fi

REQUEST_JSON=""
for fragment in "$RESIZE_JSON" "$CONVERT_JSON" "$PRESERVE_JSON"; do
  if [ -n "$fragment" ]; then
    if [ -n "$REQUEST_JSON" ]; then
      REQUEST_JSON="$REQUEST_JSON,$fragment"
    else
      REQUEST_JSON="$fragment"
    fi
  fi
done

if [ -n "$REQUEST_JSON" ]; then
  REQUEST_JSON="{$REQUEST_JSON}"
fi

trap cleanup EXIT INT TERM HUP
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/tinypng.XXXXXX")

UPLOAD_HEADERS="$TMP_DIR/upload.headers"
UPLOAD_BODY="$TMP_DIR/upload.body"
RESULT_BODY="$TMP_DIR/result.body"

upload_status=$(
  curl \
    --silent \
    --show-error \
    --dump-header "$UPLOAD_HEADERS" \
    --output "$UPLOAD_BODY" \
    --write-out "%{http_code}" \
    --user "api:$TINYPNG_API_KEY" \
    --data-binary "@$INPUT" \
    "$API_URL"
)

case "$upload_status" in
  2??)
    ;;
  *)
    printf 'Upload failed with HTTP status %s.\n' "$upload_status" >&2
    print_error_body "$UPLOAD_BODY"
    exit 1
    ;;
esac

LOCATION=$(header_value "$UPLOAD_HEADERS" "Location")
[ -n "$LOCATION" ] || fail "TinyPNG response did not include a Location header."

if [ -n "$REQUEST_JSON" ]; then
  result_status=$(
    curl \
      --silent \
      --show-error \
      --output "$RESULT_BODY" \
      --write-out "%{http_code}" \
      --user "api:$TINYPNG_API_KEY" \
      --header "Content-Type: application/json" \
      --data "$REQUEST_JSON" \
      "$LOCATION"
  )
else
  result_status=$(
    curl \
      --silent \
      --show-error \
      --output "$RESULT_BODY" \
      --write-out "%{http_code}" \
      --user "api:$TINYPNG_API_KEY" \
      "$LOCATION"
  )
fi

case "$result_status" in
  2??)
    ;;
  *)
    printf 'Result request failed with HTTP status %s.\n' "$result_status" >&2
    print_error_body "$RESULT_BODY"
    exit 1
    ;;
esac

mv "$RESULT_BODY" "$OUTPUT"

input_size=$(wc -c < "$INPUT" | tr -d ' ')
output_size=$(wc -c < "$OUTPUT" | tr -d ' ')

printf 'Input: %s\n' "$INPUT"
printf 'Output: %s\n' "$OUTPUT"
printf 'Original bytes: %s\n' "$input_size"
printf 'Result bytes: %s\n' "$output_size"
