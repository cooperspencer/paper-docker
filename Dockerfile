
FROM openjdk:16-slim AS build

ARG paperspigot_ci_url=https://papermc.io/api/v1/paper/1.17.1/latest/download
ENV PAPERSPIGOT_CI_URL=$paperspigot_ci_url

WORKDIR /opt/minecraft

# Download paperclip
ADD ${PAPERSPIGOT_CI_URL} paperclip.jar

# Run paperclip and obtain patched jar
RUN /usr/local/openjdk-16/bin/java -jar /opt/minecraft/paperclip.jar; exit 0

# Copy built jar
RUN mv /opt/minecraft/cache/patched*.jar paper.jar

FROM openjdk:16-slim AS runtime

# Working directory
WORKDIR /data

# Obtain runable jar from build stage
COPY --from=build /opt/minecraft/paper.jar /opt/minecraft/paper.jar

# Install and run rcon
ADD https://github.com/itzg/rcon-cli/releases/download/1.4.8/rcon-cli_1.4.8_linux_amd64.tar.gz /tmp/rcon-cli.tgz
RUN tar -x -C /usr/local/bin -f /tmp/rcon-cli.tgz rcon-cli && \
  rm /tmp/rcon-cli.tgz

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

WORKDIR /data

# Entrypoint with java optimisations
ENTRYPOINT /usr/local/openjdk-16/bin/java -jar -Xms$MEMORYSIZE -Xmx$MEMORYSIZE $JAVAFLAGS /opt/minecraft/paper.jar --nojline nogui