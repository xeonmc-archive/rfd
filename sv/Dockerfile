FROM steamcmd/steamcmd as downloader
USER root
WORKDIR /steam/reflex
WORKDIR /usr/bin
RUN steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir /steam/reflex +app_update 329740 +quit
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
