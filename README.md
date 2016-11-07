## java
### mvn-pull.sh
```
DOCUMENTATION:
  mvn-pull.sh is a bash script to pull artifacts from a maven repository
  using curl only.

DEPENDENCIES:
  - curl

USAGE:
  mvn-pull.sh
     -r --repo-url      maven repo URL
     -d --destination   destination directory
     -g --group-id      group id of the artifact
     -a --artifact-id   artifact id
     -v --version       artifact version
     -e --extension     artifact extension(jar|zip|xml|pom...)

EXAMPLE:
  mvn-pull.sh \
    -r http://[HOST]:[PORT]/repository/maven-public \
    -d target/ \
    -g commons-io \
    -a commons-io \
    -e jar \
    -v 2.4 \
```
## node.js
### npm-pull.sh
```
DOCUMENTATION:
  npm-pull.sh is a bash script to pull artifacts from a npm repository
  using curl only.

DEPENDENCIES:
  - curl

USAGE:
  npm-pull.sh
     -r --repo-url      npm repo URL
     -d --destination   destination directory
     -p --pkg-name      package name
     -v --version       version

EXAMPLE:
  npm-pull.sh \
    -r http://[HOST]:[PORT]/repository/npm-all \
    -d target/ \
    -p npmlog \
    -v 4.0.0 \
```
