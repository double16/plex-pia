# plex-pia
[![GitHub Issues](https://img.shields.io/github/issues-raw/double16/plex-pia.svg)](https://github.com/double16/plex-pia/issues)
[![Build](https://github.com/double16/plex-pia/workflows/Build/badge.svg)](https://github.com/double16/plex-pia/actions?query=workflow%3ABuild)
[![](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/patDj)

Runs Plex Media Server through Private Internet Access VPN with port forwarding

If your Plex Media Server cannot allow incoming connects because of your ISP, using the Private Internet Access VPN
can help. This container will handle connecting PMS through PIA and configuring a forwarded port in PIA. You do not
need to configure anything in your home router. This container will update PMS with the VPN IP and port as needed.

You must have a [Private Internet Access](https://privateinternetaccess.com) account for this to work. The `plexpia`
volume is used to hold credentials. The `/config/pia-auth.conf` contains the username on line 1 and password on line 2.
If your Plex Media Server requires a token for local network connections, put the token in `/config/plex-token.txt`.

Example docker-compose.yml:

```yaml
volumes:
  plexpia:

services:
  plex-pia:
    image: ghcr.io/double16/plex-pia:main
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    privileged: true
    hostname: plex
    # PIA DNS: https://helpdesk.privateinternetaccess.com/kb/articles/using-pia-dns-in-custom-configurations
    dns:
      - 10.0.0.242
    ports:
      - 32400:32400/tcp
      - 3005:3005/tcp
      - 8324:8324/tcp
      - 32469:32469/tcp
      - 1900:1900/udp
      - 32410:32410/udp
      - 32412:32412/udp
      - 32413:32413/udp
      - 32414:32414/udp
    environment:
      - HOST_NETWORK=192.168.0.0/18
    volumes:
      - plexpia:/config

  plex:
    image: ghcr.io/double16/plex-hare:public
    restart: unless-stopped
    network_mode: "service:plex-pia"
    depends_on:
      - plex-pia
    environment:
      - ALLOWED_NETWORKS=192.168.0.0/18,172.16.0.0/12
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    devices:
      - /dev/dri:/dev/dri
      - /dev/dvb:/dev/dvb
```

After bring up the compose file below you could run the following:

```shell
$ docker exec -it plex-pia_1 /bin/sh
# cat >/config/pia-auth.conf <<EOF
username
password
EOF
# cat >/config/plex-token.txt <<EOF
plextoken
EOF
# exit
```

If the plex-pia container is restarted, it may be necessary to restart the plex container to correct the docker
network routing. If you know how to fix this, create an issue or pull request with documentation.

