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
    -g|--group-id)
    groupId="$2"
    shift
    ;;
    -a|--artifact-id)
    artifactId="$2"
    shift
    ;;
    -v|--version)
    version="$2"
    shift
    ;;
    -e|--extension)
    extension="$2"
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
artifactBaseName="${artifactId}-${version}.${extension}"
baseURL="${repoURL}/${groupId//.//}/${artifactId}/${version}"
tmpDir=$(mktemp -d); trap cleanup EXIT

##############################################################################
# functions
function print_help
{
  cat >&2 << EOF
DOCUMENTATION:
  $(basename $0) is a bash script to pull artifacts from a maven repository
  using curl only.

DEPENDENCIES:
  - curl

USAGE:
  $(basename $0)
     -r --repo-url      maven repo URL
     -d --destination   destination directory
     -g --group-id      group id of the artifact
     -a --artifact-id   artifact id
     -v --version       artifact version
     -e --extension     artifact extension(jar|zip|xml|pom...)

EXAMPLE:
  $(basename $0) \\
    -r http://[HOST]:[PORT]/repository/maven-public \\
    -d target/ \\
    -g commons-io \\
    -a commons-io \\
    -e jar \\
    -v 2.4 \\
EOF

}

function cleanup
{
  test -n "$tmpDir" && test -d "$tmpDir" && rm -rf "$tmpDir"
}

function download
{
  if echo "${version}" | grep -q '[-]SNAPSHOT$'
    then


      if ! fetchMetadata
        then
        fail
      fi

      dVersion=$(
        cat ${tmpDir}/maven-metadata.xml \
          | sed -n "/<snapshotVersions>/,/<\/snapshotVersions>/p" \
          | grep value | sort  | tail -n1 \
          | sed -r -e 's#^ +<value>(.+)</value>$#\1#'
      )
  else
    dVersion="${version}"
  fi

  artifactURL="${baseURL}/${artifactId}-${dVersion}.${extension}"
  echo "Downloading $artifactURL"
  curl --fail -sS -o "${tmpDir}/${artifactBaseName}" "${artifactURL}"

  return $?
}

function fail
{
  echo "Could not pull artifact: ${groupId}:${artifactId}:${version}:${extension}"
  exit 1
}

function fetchMetadata
{
  curl -sS -o "${tmpDir}/maven-metadata.xml" "${baseURL}/maven-metadata.xml"

  if grep -q "${groupId}"    "${tmpDir}/maven-metadata.xml" && \
     grep -q "${artifactId}" "${tmpDir}/maven-metadata.xml" && \
     grep -q "${version}"    "${tmpDir}/maven-metadata.xml"
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
# perform paramter checks
#
test -z "${repoURL}"     && echo "Please set repoURL"     && print_help && exit 1
test -z "${destination}" && echo "Please set destination" && print_help && exit 1
test -z "${groupId}"     && echo "Please set groupId"     && print_help && exit 1
test -z "${artifactId}"  && echo "Please set artifactId"  && print_help && exit 1
test -z "${version}"     && echo "Please set version"     && print_help && exit 1
test -z "${extension}"   && echo "Please set extension"   && print_help && exit 1

##############################################################################
# start

# Artifact found
if download
then
  targetPath=$(readlink -m "${destination}/${artifactBaseName}")
  echo "  -> ${targetPath}"
  mv "${tmpDir}/${artifactBaseName}" "${targetPath}"
else
  fail
fi
