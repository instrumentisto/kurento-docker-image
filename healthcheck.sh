#!/usr/bin/env bash

set -e

exec /usr/local/bin/goss --gossfile /goss/healthcheck.yaml serve --format json --listen-addr :${KMS_HEALTHCHECK_PORT:-9092}
