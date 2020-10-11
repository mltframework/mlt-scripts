<!-- ![docker-qt5-build](https://github.com/mltframework/mlt-scripts/workflows/docker-qt5-build/badge.svg) -->
![docker-shotcut-build](https://github.com/mltframework/mlt-scripts/workflows/docker-shotcut-build/badge.svg)

This repository contains scripts for Continuous Integration and Deployment for the MLT and Shotcut projects.

- The `teamcity` folder contains the scripts executed byour TeamCity build server. This server is legacy as we hope to
migrate to GitHub Actions.
- The `build` folder contains scripts that the TeamCity scripts or users may wish to run to build MLT applications
bundled with some depenencies.
- The `test` folder contains various test scripts executed by the `teamcity/test.sh` script.
- The `docker` folder contains `Dockerfile`s for containers that may be used by some of the build scripts or GitHub
Actions.
