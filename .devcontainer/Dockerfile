# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.166.1/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version: bionic, focal
ARG VARIANT="focal"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

ENV DEBIAN_FRONTEND=noninteractive
ENV DPATH=/dlang

RUN set -ex && \
	apt-get update && \
	apt-get install --no-install-recommends -y \
	ca-certificates \
	curl \
	libc6-dev \
	gcc \
	libevent-dev \
	libssl-dev \
	libxml2 \
	libz-dev \
	gpg \
	make \
	xz-utils \
	&& update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.gold" 20 \
	&& update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.bfd" 10

RUN groupadd --gid 1002 dlang \
  && useradd --uid 1002 --gid dlang --shell /bin/bash --create-home dlang

RUN mkdir ${DPATH}\
    && chown dlang ${DPATH}

USER dlang

RUN set -ex && \
	curl -fsS https://dlang.org/install.sh | bash -s "dmd-2.094.2" -p ${DPATH}

USER root

RUN chmod 755 -R ${DPATH}
RUN ln -s ${DPATH}/dmd-2.094.2 ${DPATH}/dc && ls ${DPATH}

ENV PATH="/dlang/dmd-2.094.2/linux/bin64:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV LIBRARY_PATH="/dlang/dmd-2.094.2/linux/lib64"
ENV LD_LIBRARY_PATH="/dlang/dmd-2.094.2/linux/lib64"