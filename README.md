Kurento media server
===============================

[![GitHub release](https://img.shields.io/github/release/instrumentisto/kurento-media-server.svg)](https://hub.docker.com/r/instrumentisto/kurento-media-server/tags) [![Build Status](https://travis-ci.org/instrumentisto/kurento-media-server.svg?branch=master)](https://travis-ci.org/instrumentisto/kurento-media-server) [![Docker Pulls](https://img.shields.io/docker/pulls/instrumentisto/kurento-media-server.svg)](https://hub.docker.com/r/instrumentisto/kurento-media-server)


## What is Kurento media server?

Kurento is an open source software project providing a platform suitable
for creating modular applications with advanced real-time communication
capabilities. For knowing more about Kurento, please visit the Kurento
project website: http://www.kurento.org.


## How to use this image

Starting a Kurento media server instance is easy. Kurento media server exposes
port 8888 for client access. So, assuming you want to map port 8888 in the
instance to local port 8888, you can start kurento media server with:

```
docker run -d --name kms -p 8888:8888 instrumentisto/kurento-media-server:latest
```

### Kurento media server logs

The kurento media server log is available through the usual way Docker exposes
logs for its containers. So assuming you named your container kms (with
`--name kms` as we did above):

```
docker logs kms
```

You also may want to follow the logs in real time, you can achieve that with `-f` or `--follow`

```
docker logs -f kms
```

### Environment variables:

#### GST_DEBUG

Can be used to set the debug level of kurento media server.

Default: Kurento*:5

#### KMS_TURN_URL

URL of [TURN][4] server.

#### KMS_STUN_IP

IP address of [STUN][4] server.

Default: ""

#### KMS_STUN_PORT

[STUN][4] server port.

Default: ""

#### KMS_HEALTHCHECK_PORT

Port of health endpoint.

Default: 9092

### Health check

To implement "health check" from the outside of the container, the [goss][5] tool is used.

Path of the health check andpoint:

```
/healthz
```

The end-point will return the test results in the JSON format and an http status of 200 or 503.


## How to build this image

Use make tasks for build the image:

```
make image
```

Run tests:

```
make test
```


## Documentation
The Kurento project provides detailed documentation including tutorials,
installation and development guides. A simplified version of the documentation
can be found on [readthedocs.org][1]. The [Open API specification][2] a.k.a. Kurento
Protocol is also available on [apiary.io][3].



[1]: https://kurento.readthedocs.io/en/stable/
[2]: https://doc-kurento.readthedocs.io/en/6.8.1/features/kurento_protocol.html
[3]: https://streamoriented.docs.apiary.io/#reference/json-rpc-messages-format
[4]: https://doc-kurento.readthedocs.io/en/6.9.0/user/faq.html#install-coturn-turn-stun-server
[5]: https://github.com/aelsabbahy/goss/blob/master/docs/manual.md
