# Base dependencies.
FROM ubuntu:16.04 AS base

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83 \
     && echo "deb http://ubuntu.openvidu.io/dev xenial kms6" | tee /etc/apt/sources.list.d/kurento.list \
     && apt-get update \
     && apt-get install -y --no-install-recommends wget bzip2 


# Build libnice fork from https://github.com/alexlapa/libnice.
FROM base AS libnice

RUN apt-get install -y --no-install-recommends \
                        build-essential \
                        cmake \
                        autotools-dev \
                        dh-autoreconf \
                        cdbs \
                        libglib2.0-dev \
                        libgnutls-dev \
                        gtk-doc-tools \

# Install custom libnice
    && wget -O libnice.tar.gz https://github.com/alexlapa/libnice/archive/master.tar.gz \
    && tar -xvzf libnice.tar.gz \
    && cd libnice-master \
    && ./autogen.sh \
    && ./configure --libdir=/usr/lib/x86_64-linux-gnu/libnice/ \
    && make -j8 \
    && make install


# Install gStreamer with plugins.
FROM base AS gstreamer

RUN  apt-get install -y --no-install-recommends \
                        gstreamer1.5-plugins-base \
                        gstreamer1.5-plugins-good \
                        gstreamer1.5-plugins-bad \
                        gstreamer1.5-plugins-ugly \
                        gstreamer1.5-libav \
                        gstreamer1.5-nice \
                        gstreamer1.5-tools \
                        gstreamer1.5-x \
                        openh264-gst-plugins-bad-1.5 \
                        openwebrtc-gst-plugins
# Update libnice.
COPY --from=libnice /usr/lib/x86_64-linux-gnu/libnice/ /usr/lib/x86_64-linux-gnu/

RUN ldconfig -n /usr/lib/x86_64-linux-gnu



# Build Kurento media server.
FROM gstreamer AS dist


# CMake accepts the following build types: Debug, Release, RelWithDebInfo. So, for a Release build,
# you would run TYPE=Release instead of TYPE=Debug.
ARG TYPE=Release

RUN  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83 \
        && echo "deb http://ubuntu.openvidu.io/dev xenial kms6" | tee /etc/apt/sources.list.d/kurento.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
                        build-essential \
                        cmake \
                        software-properties-common \
                        autotools-dev \
                        dh-autoreconf \
                        debhelper \
                        default-jdk \
                        gdb \
                        gcc \
                        git openssh-client \
                        maven \
                        pkg-config \
                        # 'maven-debian-helper' installs an old Maven version in Ubuntu 14.04 (Trusty),
                        # so this ensures that the effective version is the one from 'maven'.
                        maven-debian-helper- \
                        # System development libraries
                        libboost-dev \
                        libboost-filesystem-dev \
                        libboost-regex-dev \
                        libboost-system-dev \
                        libboost-test-dev \
                        libboost-thread-dev \
                        libevent-dev \
                        libglibmm-2.4-dev \
                        libopencv-dev \
                        libsigc++-2.0-dev \
                        libsoup2.4-dev \
                        libssl-dev \
                        libvpx-dev \
                        libxml2-utils \
                        uuid-dev \
                        libgstreamer1.5-dev \
                        libgstreamer-plugins-base1.5-dev \
                        openwebrtc-gst-plugins-dev \
                        libnice-dev \
                        kmsjsoncpp-dev \
                        libboost-log-dev \
                        libboost-program-options-dev \
                        libglibmm-2.4-dev

# Builds Kurento media server project.
RUN git clone https://github.com/Kurento/kms-omni-build.git
WORKDIR /kms-omni-build
RUN git checkout 722df59b98dcdeda12151ee2d3a32c847e3fee62 \
    && git config -f .gitmodules submodule.kms-cmake-utils.commit b931efc0f5f095698956ba29f85b4aa1d784e3e0 \
    && git config -f .gitmodules submodule.kms-jsonrpc.commit 70a71812f21d5cd0cc9d4fb36c19ae48ca2f05bd \
    && git config -f .gitmodules submodule.kms-core.commit fe35efe08815926dbe511b1063cf7dbb2b91563e \
    && git config -f .gitmodules submodule.kurento-module-creator.commit 9683681dcb1bad8c5cc5d42ea313973f5857115d \
    && git config -f .gitmodules submodule.kms-elements.commit 85071d7acf47a2a87e1fa772acad2f686b7a14b4 \
    && git config -f .gitmodules submodule.kms-filters.commit cd1bab9e52864fc27a704f81dcf6ae9165ec0c78 \
    && git config -f .gitmodules submodule.kurento-media-server.commit d7c98feb60938c8b4da952363fd98da2f1f1b869 \
    && git submodule update --init --recursive \
    && git submodule update --remote \
    && mkdir build
RUN cat .gitmodules
WORKDIR build
RUN cmake -DCMAKE_BUILD_TYPE=$TYPE \
          -DENABLE_ANALYZER_ASAN=ON \
          -DSANITIZE_ADDRESS=ON \
          -DSANITIZE_THREAD=ON \
          -DSANITIZE_LINK_STATIC=ON .. \
    && make

WORKDIR /

# Creates directories.
RUN mkdir -p /dist/kurento-media-server/server/config/kurento \
    && mkdir -p /dist/kurento-media-server/plugins \
    && mkdir -p /dist/usr/local/lib \
    # Copy binary kurento-media-server.
    && cp /kms-omni-build/build/kurento-media-server/server/kurento-media-server /dist/kurento-media-server/server/kurento-media-server \
    # Copy kurento config.
    && cp /kms-omni-build/kurento-media-server/kurento.conf.json  /dist/kurento-media-server/server/config/kurento.conf.json \
    # Copy additional configuration files.
    && cp /kms-omni-build/kms-core/src/server/config/BaseRtpEndpoint.conf.ini /dist/kurento-media-server/server/config/kurento/BaseRtpEndpoint.conf.ini \
    && cp /kms-omni-build/kms-elements/src/server/config/HttpEndpoint.conf.ini /dist/kurento-media-server/server/config/kurento/HttpEndpoint.conf.ini \
    && cp /kms-omni-build/kms-core/src/server/config/MediaElement.conf.ini /dist/kurento-media-server/server/config/kurento/MediaElement.conf.ini \
    && cp /kms-omni-build/kms-core/src/server/config/SdpEndpoint.conf.json /dist/kurento-media-server/server/config/kurento/SdpEndpoint.conf.json \
    && cp /kms-omni-build/kms-elements/src/server/config/WebRtcEndpoint.conf.ini /dist/kurento-media-server/server/config/kurento/WebRtcEndpoint.conf.ini \
    # Copy plugins.
    && cp /kms-omni-build/build/kms-elements/src/server/libkmselementsmodule.so /dist/kurento-media-server/plugins/libkmselementsmodule.so \
    && cp /kms-omni-build/build/kms-core/src/gst-plugins/libkmscoreplugins.so /dist/kurento-media-server/plugins/libkmscoreplugins.so \
    && cp /kms-omni-build/build/kms-filters/src/server/libkmsfiltersmodule.so /dist/kurento-media-server/plugins/libkmsfiltersmodule.so \
    && cp /kms-omni-build/build/kms-elements/src/gst-plugins/rtcpdemux/librtcpdemux.so /dist/kurento-media-server/plugins/librtcpdemux.so \
    && cp /kms-omni-build/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcendpoint.so /dist/kurento-media-server/plugins/libwebrtcendpoint.so \
    && cp /kms-omni-build/build/kms-core/src/gst-plugins/libkmscoreplugins.so /dist/kurento-media-server/plugins/libkmscoreplugins.so \
    && cp /kms-omni-build/build/kms-core/src/server/libkmscoremodule.so /dist/kurento-media-server/plugins/libkmscoremodule.so \
    && cp /kms-omni-build/build/kms-core/src/gst-plugins/vp8parse/libvp8parse.so /dist/kurento-media-server/plugins/libvp8parse.so \
    # Copy shared libs.
    && cp /kms-omni-build/build/kms-core/src/server/libkmscoreimpl.so /dist/usr/local/lib/libkmscoreimpl.so.6 \
    && cp /kms-omni-build/build/kms-jsonrpc/src/libjsonrpc.so /dist/usr/local/lib/libjsonrpc.so.6 \
    && cp /kms-omni-build/build/kms-core/src/gst-plugins/commons/libkmsgstcommons.so /dist/usr/local/lib/libkmsgstcommons.so.6 \
    && cp /kms-omni-build/build/kms-core/src/gst-plugins/commons/sdpagent/libkmssdpagent.so /dist/usr/local/lib/libkmssdpagent.so.6 \
    && cp /kms-omni-build/build/kms-filters/src/server/libkmsfiltersimpl.so /dist/usr/local/lib/libkmsfiltersimpl.so.6 \
    && cp /kms-omni-build/build/kms-elements/src/server/libkmselementsimpl.so /dist/usr/local/lib/libkmselementsimpl.so.6 \
    && cp /kms-omni-build/build/kms-elements/src/gst-plugins/webrtcendpoint/libkmswebrtcendpointlib.so /dist/usr/local/lib/libkmswebrtcendpointlib.so.6 \
    && cp /kms-omni-build/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcdataproto.so /dist/usr/local/lib/libwebrtcdataproto.so.6




# Result image.
FROM gstreamer AS kurento

# Configure environment for KMS
 # * Use default suggested logging levels:
 #   https://doc-kurento.readthedocs.io/en/latest/features/logging.html#suggested-levels
ENV GST_DEBUG="3,Kurento*:3,kms*:3,sdp*:3,webrtc*:4,*rtpendpoint:4,rtp*handler:4,rtpsynchronizer:4,agnosticbin:4"
# * Disable colors in debug logs
ENV GST_DEBUG_NO_COLOR=1

# Copy files from dist.
COPY --from=dist /dist /

# Copy run kurento media server script.
COPY ./entrypoint.sh /entrypoint.sh

COPY ./healthcheck.sh /healthcheck.sh

# Copy supervisord configuration file.
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy health check configuration.
COPY ./healthcheck.yaml /goss/healthcheck.yaml

RUN apt-get install -y --reinstall ca-certificates \
    && apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    curl \
    kmsjsoncpp \
    libboost-log1.58.0 \
    libboost-program-options1.58.0 \
    libglibmm-2.4-1v5 \
    libsigc++-2.0-0v5 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -s  usr/local/lib/libjsonrpc.so.6 /kurento-media-server/plugins/libjsonrpc.so \
    && ln -s /usr/local/lib/libkmssdpagent.so.6 /kurento-media-server/plugins/libkmssdpagent.so \
    && ln -s /usr/local/lib/libkmsgstcommons.so.6 /kurento-media-server/plugins/libkmsgstcommons.so \
    && ln -s /usr/local/lib/libkmswebrtcendpointlib.so.6 /kurento-media-server/plugins/libkmswebrtcendpointlib.so.6 \
    && ln -s /usr/local/lib/libkmselementsimpl.so.6 /kurento-media-server/plugins/libkmselementsimpl.so.6 \
    && ln -s /usr/local/lib/libkmsfiltersimpl.so.6 /kurento-media-server/plugins/libkmsfiltersimpl.so.6 \
    && ln -s /usr/local/lib/libwebrtcdataproto.so.6 /kurento-media-server/plugins/libwebrtcdataproto.so \
    && ln -s /usr/local/lib/libkmscoreimpl.so.6 /kurento-media-server/plugins/libkmscoreimpl.so \
    && ldconfig \
    && chmod 777 /entrypoint.sh \
    && mkdir -p /var/log/supervisor \
    && curl -fsSL https://goss.rocks/install | sh

# Expose Kurento media server web-socket port.
EXPOSE 8888

# Expose health check port.
EXPOSE 9092

WORKDIR /kurento-media-server

ENTRYPOINT ["/usr/bin/supervisord"]
