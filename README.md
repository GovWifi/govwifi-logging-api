# GovWifi Logging API

The GovWifi frontend uses this API to record each FreeRADIUS authentication request.
Records are stored in a database and used for reporting and debugging.

> N.B.
>
> The private GovWifi [build repository][build-repo] contains instructions on 
> how to build GovWifi end-to-end; the sites, services and infrastructure.

## Table of Contents

- [Overview](#overview)
  - [Sinatra routes](#sinatra-routes)
  - [Stored data](#stored-data)
- [Statistics sent to the performance platform](#statistics-sent-to-the-performance-platform)
  - [Send statistics manually](#send-statistics-manually)
    - [Daily statistics](#daily-statistics)
    - [Weekly statistics](#weekly-statistics)
    - [Monthly statistics](#monthly-statistics)
- [Developing](#developing)
  - [Makefile targets](#makefile-targets)
  - [Running the API locally](#running-the-api-locally)
  - [Sample POST parameters](#sample-post-parameters)
- [Deploying](#deploying)
- [How to contribute](#how-to-contribute)
- [Licence](#licence)

## Overview

During the FreeRADIUS `post-auth` phase a POST request is sent to this API 
containing a session payload, received at the following endpoint:

```ruby
/logging/post-auth
```

The API receives this payload and saves it to a `sessions` table in its database.

The application is also responsible for sending usage statistics to the Performance Platform.

### Sinatra routes

- `GET /` — returns `{"status": "ok"}`; used by the Kubernetes health check
- `GET /healthcheck` — returns `Healthy`; used by the AWS ELB target group
- `POST /logging/post-auth` — persists a session record

#### Stored data

Each record stores:

- username
- MAC address
- Called station ID (building identifier)
- Site IP address
- Authentication result (success / failure)
- Task ID and authentication reply
- EAP type (connection type)

For certificate-based (EAP-TLS) sessions it also stores the certificate details 
(name, serial, issuer and subject).

## Statistics sent to the Performance Platform

The API publishes usage statistics to the Performance Platform, both to an S3 
bucket and to Elasticsearch. Available metrics include active users, completion 
rate, new / inactive users, roaming users, user devices and volumetrics.

Statistics are generated for three periods: `daily`, `weekly` and `monthly`.

### Send statistics manually

You can trigger statistics to be sent manually by running a Rake task. 
Populate the date argument with the date you want the statistics for.

#### Daily statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX","subnet-XXXXXXXX","subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX","sg-XXXXXXXX"]}}' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_daily_metrics[2018-12-01]"] }] }'
```

#### Weekly statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX","subnet-XXXXXXXX","subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX","sg-XXXXXXXX"]}}' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_weekly_metrics[2018-12-01]"] }] }'
```

#### Monthly statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX","subnet-XXXXXXXX","subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX","sg-XXXXXXXX"]}}' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_monthly_metrics[2018-12-01]"] }] }'
```

## Developing

The application has been fully containerised using Docker, and further abstracted 
by a set of [Makefile](Makefile) targets for commonly used tasks.

> Run `make` without a target to show its usage.

### Makefile targets

| Target | Description |
| --- | --- |
| `make build` | Build the Docker image |
| `make serve` | Build and start the API server (detached) |
| `make shell` | Build, start services and open a shell in the app |
| `make test` | Build, create test data and run the test suite |
| `make lint` | Run the linter (RuboCop) |
| `make stop` | Stop and remove all containers and volumes |
| `make help` | Show this help message |

### Running the API locally

You can also serve the logging API directly on your host machine, this will help
to reduce the feedback loop even further.

The instructions below run the *API* directly on your host machine whilst using 
containers to provision the databases.

Start the database services (detached):

```shell
docker compose -f docker-compose-local-dev.yml up -d
```

This exposes the databse on `127.0.0.1:53306` (root password `password`).

Next, create the databases and load the user schema:

```shell
mysql -uroot -ppassword -h127.0.0.1 -P53306 -e "CREATE DATABASE userdb"
mysql -uroot -ppassword -h127.0.0.1 -P53306 -e "CREATE DATABASE sessiondb"
mysql -uroot -ppassword -h127.0.0.1 -P53306 -D userdb < mysql_user/schema.sql
```

Set the environment variables and run the API:

```shell
export DB_NAME=sessiondb
export DB_PASS=password
export DB_USER=root
export DB_PORT=53306
export DB_HOSTNAME=127.0.0.1
export DB_READ_REPLICA_HOSTNAME=127.0.0.1
export USER_DB_NAME=userdb
export USER_DB_PASS=password
export USER_DB_USER=root
export USER_DB_PORT=53306
export USER_DB_HOSTNAME=127.0.0.1

bundle exec rake db:migrate
bundle exec puma -p 8080
```

### Sample POST parameters

Create a file called `logging-api-post.json` with the following content:

```json
{
  "username": "test@client.org",
  "mac": "02-00-00-00-00-01",
  "called_station_id": "",
  "site_ip_address": "35.178.48.11",
  "authentication_result": "Access-Accept",
  "authentication_reply": "",
  "task_id": "902ad495ccf042d3867fba1dcabcfcb9",
  "cert_name": "Client",
  "cert_serial": "192550388a309ecf982ad7fdc0b24f13b4a1ef20",
  "cert_subject": "/CN=Client",
  "cert_issuer": "/CN=Smoke Test Intermediate CA",
  "eap_type": "TLS"
}
```

Send this payload to your locally running API instance:

```shell
curl -d@logging-api-post.json http://127.0.0.1:8080/logging/post-auth
```

> N.B.
>
> You can drop into the running databases to observe this action being persisted
> to the database.

```shell
docker compose -f docker-compose-local-dev.yml exec user_and_session_db bash
mysql -uroot -ppassword -h127.0.0.1 -P3306 -D sessiondb -e "SELECT * from sessions"
```

## Deploying

Merging to `master` automatically deploys this API to Dev and Staging via the pipeline.

[You can find in-depth instructions on our deploy process here][deploy-guide] 
(You must be a member of the GovWifi Team to access this resource).

## How to contribute

1. Fork the project
2. Create a feature or fix branch
3. Make your changes (add tests)
4. Run the linter `make lint` (resolve issues)
5. Run the test suite `make test` (resolve issues)
6. Raise a pull request

## Licence

This codebase is released under [the MIT License][mit].

[mit]: LICENCE
[build-repo]: https://github.com/GovWifi/govwifi-build
[deploy-guide]: https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/
