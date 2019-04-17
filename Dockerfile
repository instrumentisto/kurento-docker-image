
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


# Download Kurento media server project sources
RUN git clone https://github.com/Kurento/kms-omni-build.git  /.kms\
  && cd /.kms/ \
  && git checkout 8a743ec1f268c43d20e89e77619e4511109db527 \

  ## kms-elements fork
  && git config -f .gitmodules submodule.kms-elements.url https://github.com/instrumentisto/kms-elements.git \
  && git config -f .gitmodules submodule.kms-elements.branch 166-up-kurento-version \

  ## init
  && git submodule update --init --recursive \

  ## kms-cmake-utils
  && cd kms-cmake-utils \
  && git checkout 4078f77091dd2bdc7bcd404a7f5aed1b860b2fef \
  && mk-build-deps --install --remove \
            --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
            "debian/control" \
  && cd .. \

  ## kms-jsonrpc
  && cd kms-jsonrpc \
  && git checkout 0951b4749e319169e69068485772ce2789ef839f \
  && mk-build-deps --install --remove \
              --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
              "debian/control" \
  && cd .. \

  ## kms-core
  && cd kms-core \
  && git checkout dcd7f64abf0e8f8c682ab7b379913c0d031a05bd \
  && mk-build-deps --install --remove \
              --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
              "debian/control" \
  && cd .. \

  ## kurento-module-creator
  && cd kurento-module-creator \
  && git checkout 5e78be8dbd56a32ab79bcfc1aeda3fa8effef4e6 \
  && mk-build-deps --install --remove \
          --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
          "debian/control" \
  && cd .. \

  ## kms-elements
  && cd kms-elements \
  && git checkout c50f4570be628ee904a518857343562c1d5b3234 \
  && mk-build-deps --install --remove \
              --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
              "debian/control" \
  && cd .. \

   ## kms-filters
   && cd kms-filters \
   && git checkout 76ed4efe05708ee3478c6a3b515cb9cfc4495854 \
   && mk-build-deps --install --remove \
               --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
               "debian/control" \
   && cd .. \

   ## kurento-media-server
   && cd kurento-media-server \
   && git checkout 8285e5c35d389be53c2246bd7d23a0da10cd59b4 \
   && mk-build-deps --install --remove \
               --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
               "debian/control" \
   && cd .. \

   && mkdir -p /.kms/build/ \
   && cd /.kms/build/ \
   && cmake -DCMAKE_BUILD_TYPE=$TYPE \
            #  integration with these tools is not really finished
            -DENABLE_ANALYZER_ASAN=OFF \
            -DSANITIZE_ADDRESS=OFF \
            -DSANITIZE_THREAD=OFF \
            -DSANITIZE_LINK_STATIC=OFF \
             .. \
    && make

RUN mkdir -p /dist/usr/lib/x86_64-linux-gnu/kurento/modules/ \
     # Copy plugins
     && cp /.kms/build/kms-elements/src/server/libkmselementsmodule.so \
           dist/usr/lib/x86_64-linux-gnu/kurento/modules/libkmselementsmodule.so \
     && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcendpoint.so \
           /dist/usr/lib/x86_64-linux-gnu/kurento/modules/libwebrtcendpoint.so \
     # Copy shared libs
     && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libkmswebrtcendpointlib.so \
          /dist/usr/lib/x86_64-linux-gnu/kurento/modules/libkmswebrtcendpointlib.so.6 \
     && cp /.kms/build/kms-elements/src/gst-plugins/webrtcendpoint/libwebrtcdataproto.so \
           /dist/usr/lib/x86_64-linux-gnu/kurento/modules/libwebrtcdataproto.so.6 \
     && cp /.kms/build/kms-core/src/gst-plugins/commons/sdpagent/libkmssdpagent.so \
            /dist/usr/lib/x86_64-linux-gnu/kurento/modules/libkmssdpagent.so.6



FROM ubuntu:bionic AS Kurento

# Configure environment
# * LANG: Set the default locale for all commands
# * DEBIAN_FRONTEND: Disable user-facing questions and messages
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    UBUNTU_VERSION=bionic \
    KMS_VERSION=6.10.0

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
