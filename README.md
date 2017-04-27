## Overview
This Docker image contains a fully built Ldap, MySql, and Grouper environment. The Grouper component has the Grouper UI, Grouper Web Services, and an active Grouper Daemon which runs the Grouper Loader and PSP modules.

> This image does not follow best Docker practices. It is intended from demo/class usage. It can also be useful for use as a base image for Grouper development.

## Running

To run the container:

```
$ docker run -d -p 10389:389 -p 8080:8080 -p 3306:3306 --name="grouper" unicon/grouper-demo
```

You can log into the Grouper UI with "banderson/password". The account is a sysadmin. Also available is "jsmith/password", which has no explicit privs. There are lots of "user" accounts that have dummy course memberships.

The LDAP admin bind account is "cn=admin,dc=example,dc=edu/password". The MySql admin account is "root/<nopassword>".

### Start-up flags

#### `disable`
The default container start-up invokes each of the major Grouper components. Each component can be disabled by setting the `disable` environment variable with the appropriate flags, seperated by commas. This is desirable for image users that are using the image for development purposes that are looking to reduce the start-up overhead.

The following `disable` flags are supported:

- DAEMON: disables the Grouper Loader/Daemon
- SAMPLE-JOBS: prevents the sample Loader groups from being created.
- TOMCAT: prevents Tomcat from starting; effectivly disables both Grouper's UI and Grouper WS.
- UI: disables Grouper UI
- WS: disables Grouper Web Services

Starting a container with -e "disable=DAEMON,WS" would be ideal for someone testing UI modifications.

> Note: Eventually `SAMPLE-JOBS` and `WS` will be disabled by default.

#### `enable`
The `enable` environment can be used to enable or install optional components. The following `enable` flags are supported:

- TIER: installs the *Internet2's Trust and Identity in Education and Research (TIER)* Grouper Deployment Guide reference folder structure.

### Docker Compose
Users may find it easier to use a docker-compose file to start the container:

```
version: "3.1"

services:
  grouper:
#    if you are applying changes to the grouper-demo image via another Dockerfile, uncomment `build` and set it appropriately
#    build: ./grouper/

#   Disables the sample Loader jobs and Grouper Web Services    
    environment:
     - disable=SAMPLE-JOBS,WS

#    if you are applying changes to the grouper-demo image via another Dockerfile, comment out `image`, and use `build`.
    image: unicon/grouper-demo

    ports:
     - "10389:389"
     - "3306:3306"
     - "8080:8080"
```

## Building

From source:

```
$ docker build --tag="unicon/grouper-demo" github.com/UniconLabs/grouper-demo-docker
```

## Authors

  * John Gasper (jgasper@unicon.net)
  * David Langenberg (dlangenberg@unicon.net)

## LICENSE

Copyright 2015 Unicon, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
