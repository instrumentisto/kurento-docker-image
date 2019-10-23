
FROM buildpack-deps:bionic AS builder

# Configure environment:
# * LANG: Set the default locale for all commands
# * DEBIAN_FRONTEND: Disable user-facing questions and messages
# * PYTHONUNBUFFERED: Disable stdin, stdout, stderr buffering in Python
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# CMake accepts the following build types: Debug, Release, RelWithDebInfo.
# So, for a debug build, you would run TYPE=Debug instead of TYPE=Release.
ENV TYPE=Release
ENV PATH="kms-omni-build/adm-scripts:/kms-omni-build/adm-scripts/kms:$PATH"
ENV DISTRO="bionic"

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83 \
&& echo "deb http://ubuntu.openvidu.io/dev $DISTRO kms6" \
    | tee /etc/apt/sources.list.d/kurento.list

RUN apt-get update \
  && apt-get install --no-install-recommends --yes \
    gnupg devscripts equivs

WORKDIR /.kms

# Download Kurento media server project sources
RUN git clone https://github.com/Kurento/kms-omni-build.git . \
  && git checkout ee83e0f0ab62be8387e353c6e3d7914d5ecbc073

## kms-elements fork
RUN git config -f .gitmodules submodule.kms-elements.url https://github.com/instrumentisto/kms-elements.git \
  && git submodule update --init --recursive

## kms-cmake-utils
RUN cd kms-cmake-utils \
  && git checkout 7ad36b5c5e84b02a3add398fc903cb6ae5d155f6 \
  && mk-build-deps --install --remove \
            --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
            "debian/control" \
  && cd ..

## kms-jsonrpc
RUN cd kms-jsonrpc \
  && git checkout 870016e52b7abed8d45add7e192381f33f0f0b97 \
  && mk-build-deps --install --remove \
              --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
              "debian/control" \
  && cd ..

## kms-core
RUN cd kms-core \
  && git checkout 503ebf7eb9a5ee90afd88b459628e1957d574679 \
  && mk-build-deps --install --remove \
              --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
              "debian/control" \
  && cd ..

## kurento-module-creator
RUN cd kurento-module-creator \
  && git checkout 02841cad9f9344785921a6e5b07c863c9b8bd635 \
  && mk-build-deps --install --remove \
          --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
          "debian/control" \
  && cd ..

## kms-elements
RUN cd kms-elements \
  && git checkout 8dc58943c04f1155cd3ec6c1d348a0d5201a12c7 \
  && mk-build-deps --install --remove \
              --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
              "debian/control" \
  && cd ..

## kms-filters
RUN cd kms-filters \
   && git checkout 1e276c3361f00dca4d46ff7c6a98b2b889685e2e \
   && mk-build-deps --install --remove \
               --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
               "debian/control" \
   && cd ..

## kurento-media-server
RUN cd kurento-media-server \
   && git checkout 8c86fb72dbe638676aa32643b211c5117784ec1d \
   && mk-build-deps --install --remove \
               --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
               "debian/control" \
   && cd ..

RUN mkdir -p /.kms/build/ \
   && cd /.kms/build/ \
   && cmake -DCMAKE_BUILD_TYPE=$TYPE \
            #  integration with these tools is not really finished
            -DENABLE_ANALYZER_ASAN=OFF \
            -DSANITIZE_ADDRESS=OFF \
            -DSANITIZE_THREAD=OFF \
            -DSANITIZE_LINK_STATIC=OFF \
             .. \
    && make -j$(nproc)

RUN mkdir -p /dist/usr/lib/x86_64-linux-gnu/ \
     && mkdir -p /dist/etc/kurento/modules/kurento/ \
     && mkdir -p /dist/usr/bin/ \
     # Copy plugins
     && cp /.kms/build/kms-elements/src/server/libkmselementsmodule.so \
           /dist/usr/lib/x86_64-linux-gnu/libkmselementsmodule.so \
     && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcendpoint.so \
           /dist/usr/lib/x86_64-linux-gnu/libwebrtcendpoint.so \
     # Copy shared libs
     && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libkmswebrtcendpointlib.so \
          /dist/usr/lib/x86_64-linux-gnu/libkmswebrtcendpointlib.so.6 \
     && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcdataproto.so \
           /dist/usr/lib/x86_64-linux-gnu/libwebrtcdataproto.so.6 \
     && cp /.kms/build/kms-core/src/gst-plugins/commons/sdpagent/libkmssdpagent.so \
            /dist/usr/lib/x86_64-linux-gnu/libkmssdpagent.so.6 \
     && cp /.kms/build/kms-elements/src/server/libkmselementsimpl.so \
           /dist/usr/lib/x86_64-linux-gnu/libkmselementsimpl.so.6 \
     && cp /.kms/kms-elements/src/server/config/WebRtcEndpoint.conf.ini \
            /dist/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini \
     && cp /.kms/build/kurento-media-server/server/kurento-media-server \
           /dist/usr/bin/kurento-media-server



FROM ubuntu:bionic AS Kurento

# Configure environment
# * LANG: Set the default locale for all commands
# * DEBIAN_FRONTEND: Disable user-facing questions and messages
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    UBUNTU_VERSION=bionic \
    KMS_VERSION=6.12.0

# Configure environment for KMS
# * Use default suggested logging levels:
#   https://doc-kurento.readthedocs.io/en/latest/features/logging.html#suggested-levels
# * Disable colors in debug logs
ENV GST_DEBUG="3,Kurento*:4,kms*:4,sdp*:4,webrtc*:4,*rtpendpoint:4,rtp*handler:4,rtpsynchronizer:4,agnosticbin:4" \
    GST_DEBUG_NO_COLOR=1


COPY rootfs /


# Install GnuPG, needed for `apt-key adv` (since Ubuntu 18.04)
RUN apt-get update \
 && apt-get install --yes \
        gnupg \
        supervisor \
        curl \
        net-tools \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure apt-get
# * Disable installation of recommended and suggested packages
# * Add Kurento package repository
RUN echo 'APT::Install-Recommends "false";' >/etc/apt/apt.conf.d/00recommends \
 && echo 'APT::Install-Suggests "false";' >>/etc/apt/apt.conf.d/00recommends \
 && echo "UBUNTU_VERSION=${UBUNTU_VERSION}" \
 && echo "KMS_VERSION=${KMS_VERSION}" \
 && echo "Apt source line: deb [arch=amd64] http://ubuntu.openvidu.io/${KMS_VERSION} ${UBUNTU_VERSION} kms6" \
 && echo "deb [arch=amd64] http://ubuntu.openvidu.io/${KMS_VERSION} ${UBUNTU_VERSION} kms6" >/etc/apt/sources.list.d/kurento.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83

# Install Kurento Media Server
RUN apt-get update \
 && apt-get install --yes \
        kurento-media-server \
 ; apt-get clean && rm -rf /var/lib/apt/lists/* \

  # Ensure correct rights on executables
  && chmod +x /entrypoint.sh \
              /healthcheck.sh \

  && ldconfig \
  # Install goss tool
  && (curl -fsSL https://goss.rocks/install | sh)

COPY --from=builder /dist /

EXPOSE 8888

ENTRYPOINT ["/usr/bin/supervisord"]
