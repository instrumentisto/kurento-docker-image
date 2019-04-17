#!/bin/bash -x

set -e

 echo ";; Web RTC endpoint configuration" \
    > /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini

if [ -n "$KMS_TURN_URL" ]; then
  echo "turnURL=$KMS_TURN_URL" \
    >> /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
fi

if [ -n "$KMS_STUN_IP" -a -n "$KMS_STUN_PORT" ]; then
  echo "stunServerAddress=$KMS_STUN_IP" \
    >> /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
  echo "stunServerPort=$KMS_STUN_PORT" \
    >> /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
fi

if [ -n "$KMS_EXTERNAL_IPS" ]; then
  echo "externalIPs=$KMS_EXTERNAL_IPS" \
    >> /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
fi

# Remove IPv6 local loop until IPv6 is supported
cat /etc/hosts | sed '/::1/d' | tee /etc/hosts > /dev/null

exec /usr/bin/kurento-media-server "$@"
