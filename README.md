# GovWifi Logging API

The GovWifi frontend uses this API to record each authentication request. It is stored in a database and this data is used for reporting and debugging.

N.B. The private GovWifi [build repository][build-repo] contains instructions on how to build GovWifi end-to-end - the sites, services and infrastructure.

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

Also known as `post-auth` in FreeRadius terms, this logs to the sessions table when a user has authenticated successfully or unsuccessfully.

During the RADIUS `post-auth` action, a POST request is sent to this API containing session data. This API receives this request and saves it to a database.

This application is also responsible for sending statistics to the Performance Platform.

It stores the following details along with this:

- username
- MAC
- Called station ID (Building Identifier)
- Site IP Address

This is useful for debugging and populating last_login of the user.

### Sinatra routes

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

- Account Usage
- Unique Users

### Send statistics manually

You can trigger statistics to be sent manually by running the command
below locally.

Populate the date argument to the Rake task with the date that you
want to send the statistics for.

#### Weekly Statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX","subnet-XXXXXXXX","subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX","sg-XXXXXXXX","sg-XXXXXXXX"]}}' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_weekly_metrics[2018-12-01]"] }] }'
```

#### Monthly Statistics

```shell
aws ecs run-task --cluster wifi-api-cluster \
  --task-definition logging-api-scheduled-task-wifi --count 1 --region eu-west-2 \
  --launch-type FARGATE --platform-version 1.3.0 \
  --network-configuration '{ "awsvpcConfiguration": { "assignPublicIp": "ENABLED", "subnets": ["subnet-XXXXXXXX","subnet-XXXXXXXX","subnet-XXXXXXXXXXXXXXXX"], "securityGroups": ["sg-XXXXXXXX","sg-XXXXXXXX","sg-XXXXXXXX"]}}' \
  --overrides '{ "containerOverrides": [{ "name": "logging", "command": ["bundle", "exec", "rake", "publish_monthly_metrics[2018-12-01]"] }] }'
```

## Developing

The [Makefile](Makefile) contains commonly used commands for working with this app:

- `make test` runs all the automated tests.
- `make serve` starts the API server on localhost.
- `make lint` runs the gov-uk linter.

### Deploying changes

Merging to `master` will automatically deploy this API to Dev and Staging via the Pipeline
[You can find in depth instructions on using our deploy process here](https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/) (you must be member of the GovWifi Team to access this document).

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
