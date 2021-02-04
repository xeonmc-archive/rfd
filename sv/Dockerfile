FROM ubuntu:16.04 as downloader
RUN apt-get update  && apt-get dist-upgrade -y &&\
	apt-get install -y wget lib32gcc1 lib32stdc++6
RUN useradd -m steam
RUN mkdir -p /steam/steamcmd_linux
RUN chown -R steam /steam
USER steam
WORKDIR /steam/steamcmd_linux
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz 
RUN tar -xf steamcmd_linux.tar.gz
RUN ./steamcmd.sh +login anonymous +quit
RUN mkdir /steam/reflex
RUN ./steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir ../reflex +app_update 329740 +quit
WORKDIR /steam/reflex
RUN rm -R -- */

FROM i386/alpine:3.10.5
USER root
RUN apk update &&\
    apk add wine freetype

COPY --from=downloader /steam/reflex /reflex
ADD ./shippingMaps /reflex/maps
ADD ./shippingConfigs /reflex/

ADD start-reflex.sh /reflex/

WORKDIR /reflex

CMD ["sh", "/reflex/start-reflex.sh"]
