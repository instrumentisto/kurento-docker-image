Kurento media server Docker image
=================================

[![GitHub release](https://img.shields.io/github/release/instrumentisto/kurento-docker-image.svg)](https://github.com/instrumentisto/kurento-docker-image/releases) [![Build Status](https://travis-ci.org/instrumentisto/kurento-docker-image.svg?branch=master)](https://travis-ci.org/instrumentisto/kurento-docker-image) [![Docker Pulls](https://img.shields.io/docker/pulls/instrumentisto/kurento.svg)](https://hub.docker.com/r/instrumentisto/kurento)




## What is Kurento media server?

Kurento is an open source software project providing a platform suitable for creating modular applications with advanced real-time communication capabilities. 

Kurento is part of [FIWARE]. For further information on the relationship of FIWARE and Kurento check the [Kurento FIWARE Catalog Entry]

Kurento is part of the [NUBOMEDIA] research initiative.

[FIWARE]: http://www.fiware.org
[Kurento FIWARE Catalog Entry]: http://catalogue.fiware.org/enablers/stream-oriented-kurento
[NUBOMEDIA]: http://www.nubomedia.eu

> [www.kurento.org](http://www.kurento.org)

> [github.com/kurento](https://github.com/kurento)

![Kurento Logo](http://www.kurento.org/sites/default/files/kurento.png)




## Documentation

The Kurento project provides detailed documentation including tutorials, installation and development guides. A simplified version of the documentation can be found on [readthedocs.org][1]. The [Open API specification][2] a.k.a. Kurento Protocol is also available on [apiary.io][3].




## How to use this image

Starting a Kurento instance is easy. Kurento exposes port `8888` for client access. So, assuming you want to map port `8888` in the instance to local port `8888`, you can start Kurento with:
```bash
docker run -d --name=kms -p 8888:8888 instrumentisto/kurento-media-server
```


### Logs

Kurento log is available through the usual way Docker exposes logs for its containers. So assuming you named your container `kms` (with`--name=kms` as we did above):
```bash
docker logs kms
```

You also may want to follow the logs in real time, you can achieve that with `-f` (or `--follow`):
```bash
docker logs -f kms
```


### Health-check

To use health-check outside container make a HTTP request to health-check endpoint (`/healthz`) on health-check port (`9092` by default). It will return check results in the JSON format and `200`/`503` HTTP status code.




## Environment variables


### `KMS_TURN_URL`

URL of [TURN][4] server to be used by Kurento.

Default: empty


### `KMS_STUN_IP` and `KMS_STUN_PORT`

IP address and port of [STUN][4] server to be used by Kurento.

Default: empty


### `KMS_HEALTHCHECK_PORT`

Port to health-check endpoint on.

Default: `9092`


### `GST_DEBUG`

Can be used to set the debug level of Kurento logs.

Default: `3,Kurento*:3,kms*:3,sdp*:3,webrtc*:4,*rtpendpoint:4,rtp*handler:4,rtpsynchronizer:4,agnosticbin:4`




## Image versions


### `X`

Latest version of major `X` Kurento branch.


### `X.Y`

Latest version of minor `X.Y` Kurento branch.


### `X.Y.Z`

Latest build of concrete `X.Y.Z` version of Kurento.


### `X.Y.Z-rN`

Concrete `N` build of concrete `X.Y.Z` version of Kurento.




## License

Kurento itself is licensed under [Apache 2.0 license][91].

Kurento Docker image is licensed under [MIT license][92].




## Issues
[GitHub issue]: https://github.com/instrumentisto/kurento-docker-image/issues

We can't notice comments in the DockerHub so don't use them for reporting issue or asking question.

If you have any problems with or questions about this image, please contact us through a [GitHub issue].





[1]: https://kurento.readthedocs.io/en/stable/
[2]: https://doc-kurento.readthedocs.io/en/stable/features/kurento_protocol.html
[3]: https://streamoriented.docs.apiary.io/#reference/json-rpc-messages-format
[4]: https://doc-kurento.readthedocs.io/en/stable/user/faq.html#install-coturn-turn-stun-server
[91]: https://github.com/Kurento/kurento-media-server/blob/master/LICENSE
[92]: https://github.com/instrumentisto/kurento-docker-image/blob/master/LICENSE.md
