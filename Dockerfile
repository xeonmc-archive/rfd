FROM i386/alpine:3.10.5
USER root
RUN apk update
RUN apk add wine freetype

ADD ./reflex /reflex

ADD svstart.sh /reflex/
WORKDIR /reflex

CMD ["sh", "/reflex/svstart.sh"]