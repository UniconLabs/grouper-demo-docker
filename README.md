## Overview
This Docker image contains a fully built Ldap, MySql, and Grouper environment.

This image does not follow best Docker practices. It is intended from demo/class usage.

## Running

To run the container:

```
$ docker run -d -p 10389:389 -p 8080:8080 -p 3306:3306 --name="grouper" unicon/grouper-demo
```

You can log into the Grouper UI with "banderson/password". The account is a sysadmin. Also available is "jsmith/password", which has no explicit privs.

The LDAP admin bind account is "cn=admin,dc=example,dc=edu/password". The MySql admin account is "root/<nopassword>".

## Building

From source:

```
$ docker build --tag="jtgasper3/grouper-demo" github.com/UniconLabs/grouper-demo-docker
```

## Authors

  * John Gasper (<jgasper@unicon.net>)
  * David Langenberg (<dlangenberg@unicon.net>)

## LICENSE

Copyright 2014 Unicon, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
