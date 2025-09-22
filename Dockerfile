FROM fedora:37
LABEL maintainer "Tim Brandin <tim@relate-app.com>"

ENV ES_VERSION=8.19.4

# ARG for build-time architecture selection
# This will be set automatically by Docker buildx based on the target platform
ARG TARGETARCH

# Map Docker's TARGETARCH to Elasticsearch's architecture naming
# arm64 -> linux-aarch64
# amd64 -> linux-x86_64
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        echo "linux-aarch64" > /tmp/es_arch; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        echo "linux-x86_64" > /tmp/es_arch; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi

# Read the architecture for use in subsequent commands
ENV ARCH_FILE=/tmp/es_arch

USER root

# Update system and install JDK
RUN \
	dnf update -y && \
	dnf install -y java-11-openjdk-headless && \
	dnf clean all

# Download and install Elasticsearch
RUN \
	ARCH=$(cat /tmp/es_arch) && \
	mkdir -p /opt/elasticsearch && \
	cd /opt/elasticsearch && \
	curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ES_VERSION-$ARCH.tar.gz && \
	tar zxf elasticsearch-${ES_VERSION}-${ARCH}.tar.gz -C /opt/elasticsearch --strip-components=1 && \
	rm /opt/elasticsearch/bin/*.bat /opt/elasticsearch/bin/*.exe \
	rm -Rf /opt/elasticsearch/modules/lang-mustache /opt/elasticsearch/modules/lang-groovy /opt/elasticsearch/modules/lang-expression /opt/elasticsearch/modules/transport-netty3 \
	rm -f elasticsearch-${ES_VERSION}-${ARCH}.tar.gz && \
	useradd elasticsearch && \
	mkdir -p /opt/elasticsearch/volatile/data /opt/elasticsearch/volatile/logs && \
	chown -R elasticsearch:elasticsearch /opt/elasticsearch && \
	rm /tmp/es_arch

COPY log4j2.properties /opt/elasticsearch/config/
COPY elasticsearch.yml /opt/elasticsearch/config/
COPY jvm.options /opt/elasticsearch/config/

ENV JAVA_HOME /usr/lib/jvm/jre-11-openjdk

USER elasticsearch

WORKDIR /opt/elasticsearch

CMD ["/bin/bash", "bin/elasticsearch"]

EXPOSE 9200 9300

