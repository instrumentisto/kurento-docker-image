
FROM buildpack-deps:xenial AS builder

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
ENV PATH="/adm-scripts:/adm-scripts/kms:$PATH"

RUN git clone https://github.com/Kurento/adm-scripts.git \
 && /adm-scripts/development/kurento-repo-xenial-nightly-2018 \
 && /adm-scripts/development/kurento-install-development


FROM builder AS build

# Download Kurento media server project sources
# Download Kurento media server project sources
RUN git clone https://github.com/Kurento/kms-omni-build.git /.kms \
 && cd /.kms/ \
 && git checkout 722df59b98dcdeda12151ee2d3a32c847e3fee62 \
 ## kms-elements fork
 && git config -f .gitmodules submodule.kms-elements.url https://github.com/instrumentisto/kms-elements.git \
 && git config -f .gitmodules submodule.kms-elements.branch master \
 && git config -f .gitmodules submodule.kurento-media-server.url https://github.com/flexconstructor/kurento-media-server.git \
 && git config -f .gitmodules submodule.kurento-media-server.branch master \
 ## init
 && git submodule update --init --recursive \
 ## kms-cmake-utils
 && cd kms-cmake-utils \
 && git checkout b931efc0f5f095698956ba29f85b4aa1d784e3e0 \
 && cd .. \
 ## kms-jsonrpc
 && cd kms-jsonrpc \
 && git checkout 70a71812f21d5cd0cc9d4fb36c19ae48ca2f05bd \
 && cd .. \
 ## kms-core
 && cd kms-core \
 && git checkout fe35efe08815926dbe511b1063cf7dbb2b91563e \
 && cd .. \
 ## kurento-module-creator
 && cd kurento-module-creator \
 && git checkout 9683681dcb1bad8c5cc5d42ea313973f5857115d \
 && cd .. \
 ## kms-elements
 && cd kms-elements \
 && git checkout 6b4ad504c624c9f8c5714509ffe377ed5622a639 \
 && cd .. \
 ## kms-filters
 && cd kms-filters \
 && git checkout cd1bab9e52864fc27a704f81dcf6ae9165ec0c78 \
 && cd .. \
 ## kurento-media-server
 && cd kurento-media-server \
 && git checkout f48684873b269cbe0e32ecf1a5821c8abc090896 \
 && cd .. \
 && mkdir -p /.kms/build/ \
 && cd /.kms/build/ \
 && cmake -DCMAKE_BUILD_TYPE=$TYPE \
          -DENABLE_ANALYZER_ASAN=ON \
          -DSANITIZE_ADDRESS=ON \
          -DSANITIZE_THREAD=ON \
          -DSANITIZE_LINK_STATIC=ON \
          -DCMAKE_VERBOSE_MAKEFILE=ON \
        .. \
 && make  \

 # Prepare Kurento media server project installation
 && mkdir -p /dist/kurento-media-server/server/config/kurento/ \
 && mkdir -p /dist/kurento-media-server/plugins/ \
 && mkdir -p /dist/usr/local/lib/ \
 # Copy kurento-media-server binary
 && cp /.kms/build/kurento-media-server/server/kurento-media-server \
       /dist/kurento-media-server/server/kurento-media-server \
 # Copy Kurento config
 && cp /.kms/kurento-media-server/kurento.conf.json \
       /dist/kurento-media-server/server/config/kurento.conf.json \
 # Copy additional configuration files
 && cp /.kms/kms-core/src/server/config/BaseRtpEndpoint.conf.ini \
       /dist/kurento-media-server/server/config/kurento/BaseRtpEndpoint.conf.ini \
 && cp /.kms/kms-elements/src/server/config/HttpEndpoint.conf.ini \
       /dist/kurento-media-server/server/config/kurento/HttpEndpoint.conf.ini \
 && cp /.kms/kms-core/src/server/config/MediaElement.conf.ini \
       /dist/kurento-media-server/server/config/kurento/MediaElement.conf.ini \
 && cp /.kms/kms-core/src/server/config/SdpEndpoint.conf.json \
       /dist/kurento-media-server/server/config/kurento/SdpEndpoint.conf.json \
 && cp /.kms/kms-elements/src/server/config/WebRtcEndpoint.conf.ini \
       /dist/kurento-media-server/server/config/kurento/WebRtcEndpoint.conf.ini \
 # Copy plugins
 && cp /.kms/build/kms-elements/src/server/libkmselementsmodule.so \
       /dist/kurento-media-server/plugins/libkmselementsmodule.so \
 && cp /.kms/build/kms-core/src/gst-plugins/libkmscoreplugins.so \
       /dist/kurento-media-server/plugins/libkmscoreplugins.so \
 && cp /.kms/build/kms-filters/src/server/libkmsfiltersmodule.so \
       /dist/kurento-media-server/plugins/libkmsfiltersmodule.so \
 && cp /.kms/build/kms-elements/src/gst-plugins/rtcpdemux/librtcpdemux.so \
       /dist/kurento-media-server/plugins/librtcpdemux.so \
 && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcendpoint.so \
       /dist/kurento-media-server/plugins/libwebrtcendpoint.so \
 && cp /.kms/build/kms-core/src/gst-plugins/libkmscoreplugins.so \
       /dist/kurento-media-server/plugins/libkmscoreplugins.so \
 && cp /.kms/build/kms-core/src/server/libkmscoremodule.so \
       /dist/kurento-media-server/plugins/libkmscoremodule.so \
 && cp /.kms/build/kms-core/src/gst-plugins/vp8parse/libvp8parse.so \
       /dist/kurento-media-server/plugins/libvp8parse.so \
 # Copy shared libs
 && cp /.kms/build/kms-core/src/server/libkmscoreimpl.so \
       /dist/usr/local/lib/libkmscoreimpl.so.6 \
 && cp /.kms/build/kms-jsonrpc/src/libjsonrpc.so \
       /dist/usr/local/lib/libjsonrpc.so.6 \
 && cp /.kms/build/kms-core/src/gst-plugins/commons/libkmsgstcommons.so \
       /dist/usr/local/lib/libkmsgstcommons.so.6 \
 && cp /.kms/build/kms-core/src/gst-plugins/commons/sdpagent/libkmssdpagent.so \
       /dist/usr/local/lib/libkmssdpagent.so.6 \
 && cp /.kms/build/kms-filters/src/server/libkmsfiltersimpl.so \
       /dist/usr/local/lib/libkmsfiltersimpl.so.6 \
 && cp /.kms/build/kms-elements/src/server/libkmselementsimpl.so \
       /dist/usr/local/lib/libkmselementsimpl.so.6 \
 && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libkmswebrtcendpointlib.so \
       /dist/usr/local/lib/libkmswebrtcendpointlib.so.6 \
 && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcdataproto.so \
       /dist/usr/local/lib/libwebrtcdataproto.so.6


# Result image
FROM ubuntu:xenial AS kurento

# Use default suggested logging levels:
# https://doc-kurento.readthedocs.io/en/latest/features/logging.html#suggested-levels
ENV GST_DEBUG="3,Kurento*:3,kms*:3,sdp*:3,webrtc*:4,*rtpendpoint:4,rtp*handler:4,rtpsynchronizer:4,agnosticbin:4" \
    # Disable colors in debug logs
    GST_DEBUG_NO_COLOR=1

COPY --from=build /dist /

COPY rootfs /

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83 \
 && echo "deb http://ubuntu.openvidu.io/dev xenial kms6" \
    | tee /etc/apt/sources.list.d/kurento.list
# Complete installation
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
                       --reinstall ca-certificates \
            curl \
            wget \
            bzip2 \
            supervisor \
            net-tools \
            kmsjsoncpp \
            libboost-log1.58.0 \
            libboost-program-options1.58.0 \
            libglibmm-2.4-1v5 \
            libsigc++-2.0-0v5 \
            gstreamer1.5-plugins-base \
            gstreamer1.5-plugins-good \
            gstreamer1.5-plugins-bad \
            gstreamer1.5-plugins-ugly \
            gstreamer1.5-libav \
            gstreamer1.5-nice \
            gstreamer1.5-tools \
            gstreamer1.5-x \
            openh264-gst-plugins-bad-1.5 \
            openwebrtc-gst-plugins \
 # Fill up dynamic libs
 && ln -s /usr/local/lib/libjsonrpc.so.6 \
          /kurento-media-server/plugins/libjsonrpc.so \
 && ln -s /usr/local/lib/libkmssdpagent.so.6 \
          /kurento-media-server/plugins/libkmssdpagent.so \
 && ln -s /usr/local/lib/libkmsgstcommons.so.6 \
          /kurento-media-server/plugins/libkmsgstcommons.so \
 && ln -s /usr/local/lib/libkmswebrtcendpointlib.so.6 \
          /kurento-media-server/plugins/libkmswebrtcendpointlib.so.6 \
 && ln -s /usr/local/lib/libkmselementsimpl.so.6 \
          /kurento-media-server/plugins/libkmselementsimpl.so.6 \
 && ln -s /usr/local/lib/libkmsfiltersimpl.so.6 \
          /kurento-media-server/plugins/libkmsfiltersimpl.so.6 \
 && ln -s /usr/local/lib/libwebrtcdataproto.so.6 \
          /kurento-media-server/plugins/libwebrtcdataproto.so \
 && ln -s /usr/local/lib/libkmscoreimpl.so.6 \
          /kurento-media-server/plugins/libkmscoreimpl.so \
 && cp /kurento-media-server/server/kurento-media-server /usr/bin/kurento-media-server \
 && ldconfig \
 # Ensure correct rights on executables
 && chmod +x /entrypoint.sh \
             /healthcheck.sh \
 # Install goss tool
 && (curl -fsSL https://goss.rocks/install | sh) \
 # Cleanup stuff
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 8888

WORKDIR /kurento-media-server

ENTRYPOINT ["/usr/bin/supervisord"]
