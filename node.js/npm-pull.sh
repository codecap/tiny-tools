#!/bin/bash
##############################################################################
# parameters
while [[ $# -gt 0 ]]
do
key="$1"

  case $key in
    -r|--repo-url)
    repoURL="$2"
    shift
    ;;
    -d|--destination)
    destination="$2"
    shift
    ;;
    -p|--pkg-name)
    pkgName="$2"
    shift
    ;;
    -v|--version)
    version="$2"
    shift
    ;;
    -h|--help)
    do_printhelp="TRUE"
    shift
    ;;
    *)
    # ignore unknown options
    ;;
  esac
  shift
done

##############################################################################
# variables
baseURL="${repoURL}/${pkgName}"
extension="tgz"
pkgBaseName="${pkgName}-${version}.${extension}"
tmpDir=$(mktemp -d); trap cleanup EXIT
##############################################################################
# functions
function print_help
{
  cat >&2 << EOF
DOCUMENTATION:
  $(basename $0) is a bash script to pull artifacts from a npm repository
  using curl only.

DEPENDENCIES:
  - curl

USAGE:
  $(basename $0)
     -r --repo-url      npm repo URL
     -d --destination   destination directory
     -p --pkg-name      package name
     -v --version       version

EXAMPLE:
  $(basename $0) \\
    -r http://[HOST]:[PORT]/repository/npm-all \\
    -d target/ \\
    -p npmlog \\
    -v 4.0.0 \\
EOF

}

function cleanup
{
  test -n "$tmpDir" && test -d "$tmpDir" && rm -rf "$tmpDir"
}

function download
{

  if ! fetchMetadata
    then
    fail
  fi

  dVersion=$(
    cat ${tmpDir}/pkg-metadata.json \
      | sed 's/^.*"time"://'   | sed -e "s/,/,\n/g" \
      | egrep "\"${version}([.]|\")" | awk -F ':' '{print $1}' \
      | sed -r -e 's/(^"|"$)//g' \
      | egrep "${version}(.)?" \
      | sort | tail -n1
  )

  test -z "${dVersion}" && fail

  pkgURL="${baseURL}/-/${pkgName}-${dVersion}.${extension}"
  echo "Downloading $pkgURL"
  curl --fail -sS -o "${tmpDir}/${pkgBaseName}" "${pkgURL}"

  return $?
}

function fail
{
  echo "Could not pull package: ${pkgName}:${version}:${extension}"
  exit 1
}

function fetchMetadata
{

  curl -sS -o "${tmpDir}/pkg-metadata.json" "${baseURL}"

  if egrep -q "\"_id\":( +)?\"${pkgName}\""  "${tmpDir}/pkg-metadata.json" && \
     egrep -q "\"${version}"                 "${tmpDir}/pkg-metadata.json"
  then
   # Metadata found
    return 0
  fi

  return 1
}
##############################################################################
# checks

#
# print help and exit
#
test -n "${do_printhelp}" && print_help && exit 1

#
# perform parameter checks
#
test -z "${repoURL}"     && echo "Please set repoURL"     && print_help && exit 1
test -z "${destination}" && echo "Please set destination" && print_help && exit 1
test -z "${pkgName}"     && echo "Please set pkgName"     && print_help && exit 1
test -z "${version}"     && echo "Please set version"     && print_help && exit 1
test -z "${extension}"   && echo "Please set extension"   && print_help && exit 1

##############################################################################
# start

# Artifact found
if download
then
  targetPath=$(readlink -m "${destination}/${pkgBaseName}")
  echo "  -> ${targetPath}"
  mv "$tmpDir/${pkgBaseName}" "${targetPath}"
else
  fail
fi
