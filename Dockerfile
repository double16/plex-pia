FROM ubuntu:24.04

ARG PIA_VERSION=3.6.2-08398
ARG SYSTEMCTL_VER=ac9b3916dd069ba053e4259cf74131028935f5e1
ARG APT_PROXY
ENV DEBIAN_FRONTEND=noninteractive

RUN if [ -n "${APT_PROXY}" ]; then echo "Acquire::HTTP::Proxy \"${APT_PROXY}\";\nAcquire::HTTPS::Proxy false;\n" >> /etc/apt/apt.conf.d/01proxy; cat /etc/apt/apt.conf.d/01proxy; fi && \
    apt-get -q update && \
    apt-get -y install sudo curl python3 nano netcat-openbsd psmisc socat iptables cron \
    net-tools iproute2 libatomic1 libxkbcommon-x11-0 libxcb1 xterm libxcb-xkb1 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libnl-3-200 libnl-route-3-200 libgssapi-krb5-2 libglib2.0-0 && \
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -f /etc/apt/apt.conf.d/01proxy &&\
    rm -rf /tmp/*

ADD download.sh /tmp/
RUN /tmp/download.sh ${PIA_VERSION} && rm /tmp/download.sh

RUN curl -L -o /usr/bin/systemctl https://github.com/gdraheim/docker-systemctl-replacement/raw/${SYSTEMCTL_VER}/files/docker/systemctl3.py &&\
    chmod +x /usr/bin/systemctl

ADD *.service /etc/systemd/system/
ADD healthcheck.sh /healthcheck.sh
ADD monitor-ip-port.sh return-route.sh plex-configure.sh pia-auth.sh pia-configure.sh /usr/local/bin/
COPY push-ip-port.sh /etc/cron.hourly/push-ip-port

RUN systemctl enable pia-auth pia-configure pia-connect monitor-ip-port &&\
    useradd --home-dir /pia pia &&\
    mkdir -p /pia &&\
    chown -R pia:pia /pia &&\
    echo 'Defaults:pia !requiretty' > /etc/sudoers.d/pia &&\
    echo '%pia ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/pia &&\
    chmod 0440 /etc/sudoers.d/pia &&\
    chmod +x /usr/local/bin/*.sh /etc/cron.hourly/push-ip-port /healthcheck.sh

USER pia
WORKDIR /pia
RUN bash /tmp/pia.run --quiet --accept --noprogress --nox11 &&\
    ! ( ldd /opt/piavpn/bin/pia-daemon | grep -q 'not found' )

USER root

VOLUME /config

CMD ["/usr/bin/systemctl","default"]
HEALTHCHECK CMD /healthcheck.sh
