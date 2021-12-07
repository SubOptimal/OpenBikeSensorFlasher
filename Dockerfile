FROM curlimages/curl:7.80.0 AS builder
ARG FIRMWARE_VERSION=0.10.676

WORKDIR /tmp/obs
RUN curl --remote-name --location https://github.com/openbikesensor/OpenBikeSensorFirmware/releases/download/v${FIRMWARE_VERSION}/obs-v${FIRMWARE_VERSION}-initial-flash.zip && \
    curl --remote-name --location  https://github.com/openbikesensor/OpenBikeSensorFlash/releases/latest/download/flash.bin && \
	unzip obs-v${FIRMWARE_VERSION}-initial-flash.zip && \
	rm obs-v${FIRMWARE_VERSION}-initial-flash.zip

COPY  ./public-html/ ./
RUN sed -i "s/FIRMWARE_VERSION/${FIRMWARE_VERSION}/g" /tmp/obs/index.html && \
    sed -i "s/FIRMWARE_VERSION/${FIRMWARE_VERSION}/g" /tmp/obs/manifest.json


FROM node:lts AS nodebuilder
ARG ESP_WEB_TOOLS_VERSION=6.0.0

WORKDIR /tmp/esp-web-tool
RUN curl --remote-name --location https://github.com/esphome/esp-web-tools/archive/refs/heads/configure-improv-timeout.zip && \
#    curl --remote-name --location https://github.com/esphome/esp-web-tools/archive/refs/heads/main.zip && \
#    curl --remote-name --location https://github.com/esphome/esp-web-tools/archive/refs/tags/${ESP_WEB_TOOLS_VERSION}.zip && \
    unzip *.zip && \
    rm *.zip && \
    mv */* . && \
    npm ci  && \
    script/build && \
    npm exec -- prettier --check src


FROM httpd:2.4

COPY --from=builder /tmp/obs/ /usr/local/apache2/htdocs/
COPY --from=nodebuilder /tmp/esp-web-tool/dist/web/ /usr/local/apache2/htdocs/esp-web-tools
