ARG HIBISCUS_VERSION=2.10.24 \
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
ADD https://dlm.mariadb.com/4174416/Connectors/java/connector-java-3.5.2/mariadb-java-client-3.5.2.jar ${HIBISCUS_SERVER_PATH}/lib

FROM gcr.io/distroless/java21-debian12:nonroot as hibiscus-server
ARG HIBISCUS_VERSION \
    HIBISCUS_SERVER_PATH

COPY --chmod=775 --from=0 $HIBISCUS_SERVER_PATH $HIBISCUS_SERVER_PATH
WORKDIR $HIBISCUS_SERVER_PATH

#/cfg/de.willuhn.jameica.hbci.rmi.HBCIDBService.properties
#/cfg/de.willuhn.jameica.webadmin.Plugin.properties

CMD ["jameica-linux.jar", "-w /run/secrets/hibiscus-pwd"]
