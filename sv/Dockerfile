FROM i386/alpine:3.10.5
USER root
RUN apk update &&\
    apk add wine freetype

ADD ./reflexFromSteam /reflex
ADD ./shippingMaps /reflex/maps
ADD ./shippingConfigs /reflex/

ADD start-reflex.sh /reflex/

WORKDIR /reflex

CMD ["sh", "/reflex/start-reflex.sh"]
