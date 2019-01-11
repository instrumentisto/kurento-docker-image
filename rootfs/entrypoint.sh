#!/bin/bash -x

set -e

if [ -n "$KMS_TURN_URL" ]; then
  echo "turnURL=$KMS_TURN_URL" \
    >> /kurento-media-server/server/config/kurento/WebRtcEndpoint.conf.ini
fi

if [ -n "$KMS_STUN_IP" -a -n "$KMS_STUN_PORT" ]; then
  echo "stunServerAddress=$KMS_STUN_IP" \
    >> /kurento-media-server/server/config/kurento/WebRtcEndpoint.conf.ini
  echo "stunServerPort=$KMS_STUN_PORT" \
    >> /kurento-media-server/server/config/kurento/WebRtcEndpoint.conf.ini
fi

# Remove IPv6 local loop until IPv6 is supported
cat /etc/hosts | sed '/::1/d' | tee /etc/hosts > /dev/null

exec server/kurento-media-server \
  --modules-path=. \
  --modules-config-path=./server/config \
  --conf-file=./server/config/kurento.conf.json \
  --gst-plugin-path=.
