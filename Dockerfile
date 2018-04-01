FROM ubuntu:17.10 AS ubuntu-java

ENV JAVA_VERSION=9.0.4
ENV JAVA_BUILD=11
ENV JAVA_SIG=c2514751926b4512b076cc82f959763f
ENV JAVA_HASH=90c4ea877e816e3440862cfa36341bc87d05373d53389ec0f2d54d4e8c95daa2
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-oracle
ENV JDK_FILE=jdk-${JAVA_VERSION}-${JAVA_BUILD}_linux-x64_bin.tar.gz

COPY ./cache/java/ /tmp/cache/

# Based on https://github.com/sgr-io/docker-java-oracle/blob/master/jdk/Dockerfile
RUN echo "Java" \
   && if [ ! -f "/tmp/cache/$JDK_FILE" ]; then \
    echo "Downloading..." \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates curl apt-utils \
    && curl --location --retry 3 \
            --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
            --output "/tmp/cache/$JDK_FILE" \
            "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}+${JAVA_BUILD}/${JAVA_SIG}/jdk-${JAVA_VERSION}_linux-x64_bin.tar.gz" \
  ; fi \
  && sha256sum "/tmp/cache/$JDK_FILE" | grep "$JAVA_HASH" \
  && mkdir -p "$JAVA_HOME" \
  && tar xzf "/tmp/cache/$JDK_FILE" -C /tmp \
  && mv "/tmp/jdk-${JAVA_VERSION}"/* "$JAVA_HOME" \
  && echo "Cleaning up" \
  && apt-get -y autoclean \
  && apt-get --purge -y autoremove \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && echo "Update alternatives" \
  && update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1 \
  && update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1 \
  && update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1 \
  && update-alternatives --set java "${JAVA_HOME}/bin/java" \
  && update-alternatives --set javaws "${JAVA_HOME}/bin/javaws" \
  && update-alternatives --set javac "${JAVA_HOME}/bin/javac" \
  && echo "Done"

FROM ubuntu-java AS ubuntu-studio

ARG USER_UID
ARG USER_GID
ARG KVM_GID

ENV STUDIO_VERSION=3.1.0.16
ENV STUDIO_BUILD=173.4670197
ENV STUDIO_HASH=de2587bf5471695c8a411f979e6247c0d552ce14f5ca9de82ddeb3dc946f14c4
ENV STUDIO_FILE=android-studio-ide-${STUDIO_BUILD}-linux.zip

RUN echo "Install packages" \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends \
   xauth x11-utils tzdata \
   libxrender1 libxext6 libxtst6 libxi6 \
   kvm qemu-kvm bridge-utils pulseaudio \
   xserver-xorg-input-void \
   unzip curl ca-certificates curl apt-utils

COPY ./cache/android/ /tmp/cache/
COPY ./pulse-client.conf /tmp/

RUN echo "Download studio" \
  && if [ ! -f "/tmp/cache/$STUDIO_FILE" ]; then \
    echo "Downloading..." \
    && curl --location --retry 3 --output "/tmp/cache/$STUDIO_FILE" \
            "https://dl.google.com/dl/android/studio/ide-zips/${STUDIO_VERSION}/android-studio-ide-${STUDIO_BUILD}-linux.zip" \
  ; fi \
  && echo "KVM" \
  && groupmod --gid "$KVM_GID" kvm \
  && echo "PulseAudio" \
  && cat /tmp/pulse-client.conf | sed -e "s/\${USER_ID}/$USER_UID/g" > /etc/pulse/client.conf \
  && echo "Create user" \
  && groupadd --gid "$USER_GID" droid \
  && useradd -m --home /home/droid --uid "$USER_UID" --gid droid -G kvm --shell /bin/bash droid \
  && echo "Android Studio" \
  && sha256sum "/tmp/cache/$STUDIO_FILE" | grep "$STUDIO_HASH" \
  && unzip -qd "/home/droid/" "/tmp/cache/$STUDIO_FILE" \
  && echo "Saved state directories" \
  # .AndroidStudio location can be set in idea.properties but the emulator looks in the home directory anyway
  && ln -s /var/studio/.AndroidStudio3.1 /home/droid/.AndroidStudio3.1 \
  && ln -s /var/studio/.java /home/droid/.java \
  && echo "Permissions" \
  && chown -R droid:droid /home/droid/ \
  && echo "Cleaning up" \
  && apt-get clean -y \
  && apt-get --purge -y autoremove -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && echo "Done"

FROM ubuntu-studio

ARG DISPLAY=:0
ARG USER_UID

USER droid

ENV DISPLAY=$DISPLAY \
    PULSE_SERVER=unix:/run/user/$USER_UID/pulse/native \
    GRADLE_USER_HOME=/var/studio/.gradle \
    ANDROID_SDK_ROOT=/var/studio/Android/Sdk \
    ANDROID_SDK_HOME=/var/studio \
    ANDROID_EMULATOR_HOME=/var/studio/.android \
    ANDROID_AVD_HOME=/var/studio/.android/avd \
    ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

ENV PATH=$PATH:/home/droid/android-studio/bin:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools

WORKDIR /home/droid/

VOLUME /data/
VOLUME /var/studio/

ENTRYPOINT ["/home/droid/android-studio/bin/studio.sh"]
