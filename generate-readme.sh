#!/bin/bash
##############################################################################
#
# searches for exacutables and generates README.md using their help
# output
#
##############################################################################
readme_file="README.md"
echo -n > $readme_file
exec > $readme_file
##############################################################################
for d in $(find . -mindepth 1 -type d | grep -v "[.]/[.]git")
do
  echo "## $(basename $d)"

  for e in $(find $d -type f -executable)
  do
    echo "### $(basename $e)"
    echo '```'
    $e --help 2>&1
    echo '```'
  done
done
