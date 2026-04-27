# GovWifi Logging API

The **GovWifi Logging API** records each authentication request made through **GovWifi Frontend (FreeRADIUS)**.

## Table of Contents

- [GovWifi Logging API](#govwifi-logging-api)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Sinatra routes](#sinatra-routes)
  - [Statistics sent over to the performance platform](#statistics-sent-over-to-the-performance-platform)
    - [Send statistics manually](#send-statistics-manually)
      - [Weekly Statistics](#weekly-statistics)
      - [Monthly Statistics](#monthly-statistics)
  - [Developing](#developing)
    - [Deploying changes](#deploying-changes)
  - [How to contribute](#how-to-contribute)
  - [Licence](#licence)

## Overview

Authentication requests made to **GovWifi Frontend (FreeRADIUS)** result in
checks being performed to ensure that access is provided to valid users.

FreeRADIUS executes what it terms as `post-auth` policies as part of
the authentication request phase. For the purposes of this API, it will return
the status of the request, be it successful or unsuccessful along with other
useful session information.

This **GovWifi Logging API** receives this session data as an HTTP POST request
from FreeRADIUS during this phase which is then persisted to a session database.

The following information is available:

- Username (GovWifi User)
- MAC Address (Media Access Control)
- Called Station ID (Building Identification)
- Site IP Address (Location)
- Authentication Result (Access or Reject)

## Sinatra routes

The GovWifi Logging API is built atop the Sinatra web framework and provides
the following routes.

- `GET /` - k8s health check usually need the web root to respond with status 200
- `GET /healthcheck` - AWS ELB target group health checking
- `POST /logging/post-auth` - Persist a session record with these details:

  ```shell
  params:
    :username
    :mac
    :called_station_id
    :site_ip_address
    :authentication_result
  ```

## Statistics sent over to the performance platform

*This application is also responsible for sending statistics to the Performance Platform.*

- Account Usage
- Unique Users

### Send statistics manually

You can trigger statistics to be sent manually by running the commands below locally.

Amend the `date` argument to the Rake task with the date that you want to send
the statistics for.

#### Weekly statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX", "subnet-XXXXXXXX", "subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX", "sg-XXXXXXXX", "sg-XXXXXXXX"] } }' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_weekly_metrics[2026-04-28]"] }] }'
```

#### Monthly statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX", "subnet-XXXXXXXX", "subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX", "sg-XXXXXXXX", "sg-XXXXXXXX"] } }' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_monthly_metrics[2026-04-28]"] }] }'
```

## Developing

*N.B. The private GovWifi [build repository][build-repo] contains instructions on how to build GovWifi end-to-end - the sites, services and infrastructure.*

The [Makefile](Makefile) contains commonly used commands for working with this app:

- `make test` runs all the automated tests.
- `make serve` starts the API server on localhost.
- `make lint` runs the gov-uk linter.

### Running API outside Docker

This runs directly on the host. It provides a quicker feedback loop than running
the API via Docker.

Follow these steps to get the API running locally from your machine.

The tool [direnv](https://direnv.net/) is used to manage the environment the API depends upon.

#### Install dependencies

```shell
brew install mysql

brew install openssl@3

# Include development dependencies
bundle config set with 'test'

# Work around issue installing the ruby mysql2 gem on homebrew
#
#1 warning generated.
#compiling statement.c
#linking shared-object mysql2/mysql2.bundle
#ld: library 'zstd' not found
#clang: error: linker command failed with exit code 1 (use -v to see invocation)
#
# This may not still be an issue. It is kept for future reference.
#
gem install mysql2 -v '0.5.6' -- --with-opt-dir=$(brew --prefix openssl) --with-ldflags=-L/opt/homebrew/opt/zstd/lib

bundle install
```

#### Logging API configuration

Create a `.envrc` at the root of this checked out repository.

For example my file looked like:

```shell
export GEM_HOME=./.gems
export PATH=$GEM_HOME/bin:$PATH

export DB_NAME='sessiondb'
export DB_PASS='password'
export DB_USER='root'
export DB_PORT=53306
export DB_HOSTNAME='0.0.0.0'

export DB_READ_REPLICA_HOSTNAME='0.0.0.0'

export USER_DB_NAME='userdb'
export USER_DB_PASS='password'
export USER_DB_USER='root'
export USER_DB_PORT=53306
export USER_DB_HOSTNAME='0.0.0.0'
```

#### Starting the Logging API

```shell
# In one terminal run the dependencies needed by the Logging API:
docker compose -f docker-compose-local-dev.yml down --remove-orphans ; docker compose -f docker-compose-local-dev.yml up

# In another terminal create the databases needed for local development
mysql -uroot -ppassword -h127.0.0.1 -P53306 -e "CREATE DATABASE sessiondb"
mysql -uroot -ppassword -h127.0.0.1 -P53306 -e "CREATE DATABASE userdb"
mysql -uroot -ppassword -h127.0.0.1 -P53306 userdb < mysql_user/schema.sql

# Run the DB migrations
bundle exec rake db:migrate

# In another terminal start the Logging API and monitor its logged output
bundle exec puma --port 8080
```

#### Creating an example HTTP POST

Create a file called `logging-api-post.json` and add the following content:

```json
{
    "username": "test@client.org",
    "mac": "02-00-00-00-00-01",
    "called_station_id": "",
    "site_ip_address": "35.178.48.11",
    "cert_name": "Client",
    "authentication_result": "Access-Accept",
    "authentication_reply": "",
    "task_id": "902ad495ccf042d3867fba1dcabcfcb9",
    "cert_serial": "192550388a309ecf982ad7fdc0b24f13b4a1ef20",
    "cert_subject": "/CN=Client",
    "cert_issuer": "/CN=Smoke Test Intermediate CA",
    "eap_type": "TLS"
}
```

Now using the cURL command you can send this request to the running API instance.

```shell
curl --data @logging-api-post.json http://0.0.0.0:8080/logging/post-auth
```

Check the log output from your running instance of Puma to see that this request
is being successfully processed.

You can also launch a database console to verify that this request was
successfully added to the `sessions` table of the `sessiondb` database which was
earlier migrated.

#### Access the development MySQL instance:

```shell
# When prompted enter the password stored in the .envrc file
mysql -h 127.0.0.1 -u root -P53306 -p
```

```sql
-- Confirm the previously run HTTP POST added a new record to the sessions table
USE sessiondb;

SELECT
  COUNT(*)
FROM
  sessions;
```

#### Lint your code

There should be no offenses detected.

```shell
bundle exec rubocop
```

### Deploying changes

Merging to `master` will automatically deploy this API to Dev and Staging via the Pipeline
[You can find in depth instructions on using our deployment process here](https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/) (you must be member of the GovWifi Team to access this document).

## How to contribute

1. Fork the project
2. Create a feature or fix branch
3. Make your changes (with tests if possible)
4. Run and linter: `make lint`
5. Run and pass tests `make test`
6. Raise a pull request

## Licence

This codebase is released under [the MIT License][mit].

[mit]: LICENCE
[build-repo]: https://github.com/GovWifi/govwifi-build
