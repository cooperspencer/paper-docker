FROM eclipse-temurin:21-jre-alpine AS build

ARG TARGETARCH

ENV PAPER_CI_URL=https://api.papermc.io/v2/projects/paper/versions/1.21.8/builds/11/downloads/paper-1.21.8-11.jar
ENV RCON_URL=https://github.com/itzg/rcon-cli/releases/download/1.7.1/rcon-cli_1.7.1_linux_${TARGETARCH}.tar.gz

WORKDIR /opt/minecraft

# Download paperclip
ADD ${PAPER_CI_URL} paperclip.jar

# Install and run rcon
ADD ${RCON_URL} /tmp/rcon-cli.tgz
RUN tar -x -C /usr/local/bin -f /tmp/rcon-cli.tgz rcon-cli && \
  rm /tmp/rcon-cli.tgz

FROM eclipse-temurin:21-jre-alpine AS runtime

# Working directory
WORKDIR /data

# Obtain runable jar from build stage
COPY --from=build /opt/minecraft/paperclip.jar /opt/minecraft/paper.jar
COPY --from=build /usr/local/bin/rcon-cli /usr/local/bin/rcon-cli

# Volumes for the external data (Server, World, Config...)
VOLUME "/data"

# Expose minecraft port
EXPOSE 25565/tcp
EXPOSE 25565/udp

# Set memory size
ARG memory_size=3G
ENV MEMORYSIZE=$memory_size

# Set Java Flags
ARG java_flags="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=mcflags.emc.gs -Dcom.mojang.eula.agree=true"
ENV JAVAFLAGS=$java_flags
RUN apk add --no-cache udev

WORKDIR /data

# Entrypoint with java optimisations
ENTRYPOINT java -jar -Xms$MEMORYSIZE -Xmx$MEMORYSIZE $JAVAFLAGS /opt/minecraft/paper.jar --nojline nogui