ARG HIBISCUS_VERSION=2.10.17 \
    HIBISCUS_DOWNLOAD_PATH=/opt/hibiscus-server.zip \
    HIBISCUS_INSTALL_PATH=/opt \
    HIBISCUS_SERVER_PATH=/opt/hibiscus-server

FROM ubuntu
ARG HIBISCUS_VERSION \
    HIBISCUS_DOWNLOAD_PATH \
    HIBISCUS_INSTALL_PATH \
    HIBISCUS_SERVER_PATH
ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
    && apt install -qqy --no-install-recommends unzip

ADD https://www.willuhn.de/products/hibiscus-server/releases/hibiscus-server-${HIBISCUS_VERSION}.zip $HIBISCUS_DOWNLOAD_PATH
RUN unzip $HIBISCUS_DOWNLOAD_PATH -d $HIBISCUS_INSTALL_PATH \
    && rm ${HIBISCUS_DOWNLOAD_PATH}

#FROM eclipse-temurin:11 as hibiscus-server
FROM gcr.io/distroless/java17-debian12 as hibiscus-server
ARG HIBISCUS_VERSION \
    HIBISCUS_SERVER_PATH
ENV HIBISCUS_PASSWORD=password

COPY --chmod=775 --from=0 $HIBISCUS_SERVER_PATH $HIBISCUS_SERVER_PATH
WORKDIR $HIBISCUS_SERVER_PATH

#/cfg/de.willuhn.jameica.hbci.rmi.HBCIDBService.properties
#/cfg/de.willuhn.jameica.webadmin.Plugin.properties

CMD ["./jameicaserver.sh", "-p ${HIBISCUS_PASSWORD}"]
