#!/bin/bash
INPUT_DIR='test/input'
OUTPUT_DIR='test/output'
REF_DIR='test/ref'
CHECK_DIR='test/check'
for input_file in `find test/input -type f | sort`; do
  file="$(basename "$input_file")"
  base="${file%.*}"
  output_file="$OUTPUT_DIR/$base.webp"
  ref_file="$REF_DIR/$base.webp"
  check_file="$CHECK_DIR/$base.png"

  printf "%s: " "$file"
  mono VP8L.exe "$input_file" "$output_file" || exit $?
  test/cwebp "$input_file" -o "$ref_file" -lossless -quiet || exit $?
  test/dwebp "$output_file" -o "$check_file" -quiet || exit $?

  png_size=`stat --printf '%s' "$check_file"`
  output_size=`stat --printf '%s' "$output_file"`
  reference_size=`stat --printf '%s' "$ref_file"`
  png_ratio=$((100*output_size/png_size))
  ref_ratio=$((100*output_size/reference_size))
  printf " %d%% of PNG, %d%% of WebP\n" "$png_ratio" "$ref_ratio"
done
