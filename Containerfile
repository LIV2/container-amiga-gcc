FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install all packages
RUN apt-get -y update && \
    apt-get -y install \
      apt-utils curl git lhasa python3 python3-pip wget \
      autoconf bison flex g++ gcc gettext file libgmpxx4ldbl libgmp-dev \
      libmpfr6 libmpfr-dev libmpc3 libmpc-dev libncurses-dev make rsync \
      texinfo && \
      apt-get -y autoremove

ARG GCC_BRANCH=amiga6
ARG GCC_VERS=6.5.0

# Install Bebbo's amiga-gcc
RUN git config --global pull.rebase false && \
    cd /root && \
    git clone --depth 1 https://github.com/AmigaPorts/m68k-amigaos-gcc amiga-gcc && \
    cd /root/amiga-gcc && \
    mkdir -p /opt/amiga && \
    make branch branch=${GCC_BRANCH} mod=gcc && \
    make update && \
    make -j$(nproc) all vlink vbcc ira && \
    cd / && \
    rm -rf /root/amiga-gcc

# Install a working VBCC
RUN mkdir -p /tmp/vbcc-targets && \
    mkdir -p /opt/amiga/m68k-amigaos/vbcc/targets && \
    mkdir -p /tmp/vbcc-unix-configs && \
    curl -o /tmp/vbcc-targets/vbcc_target_m68k-amigaos.lha http://phoenix.owl.de/vbcc/2022-05-22/vbcc_target_m68k-amigaos.lha && \
    lha -xw=/tmp/vbcc-targets /tmp/vbcc-targets/vbcc_target_m68k-amigaos.lha && \
    mv /tmp/vbcc-targets/vbcc_target_m68k-amigaos/targets/m68k-amigaos /opt/amiga/m68k-amigaos/vbcc/targets/ && \ 
    curl -o /tmp/vbcc-unix-configs/vbcc_unix_config.tar.gz http://phoenix.owl.de/vbcc/2022-02-28/vbcc_unix_config.tar.gz && \
    tar -xvf /tmp/vbcc-unix-configs/vbcc_unix_config.tar.gz -C /tmp/vbcc-unix-configs && \
    mv /tmp/vbcc-unix-configs/config /opt/amiga/m68k-amigaos/vbcc/ && \
    rm -rf /tmp/vbcc-targets /tmp/vbcc-unix-configs

# Install unmodified SDK for VBCC
ENV NDK32=/opt/amiga/m68k-amigaos/NDK3.2
RUN curl -o /tmp/NDK3.2.lha https://aminet.net/dev/misc/NDK3.2.lha && \
    mkdir ${NDK32} && \
    lha -xw=${NDK32}  /tmp/NDK3.2.lha && \
    sed -i -r '/^-ccv?=/s|$| -I$NDK32/Include_H|;/^-asv?=/s|$| -I$NDK32/Include_I|' /opt/amiga/m68k-amigaos/vbcc/config/aos68k*

# Install amitools.
RUN apt -y install python3-venv && \
    python3 -m venv /opt/amiga/venv && \
    /opt/amiga/venv/bin/pip3 install 'amitools[vamos] @ git+https://github.com/cnvogelg/amitools.git'

# Install salvador ZX0 compressor
RUN git clone --depth 1 https://github.com/emmanuel-marty/salvador.git /tmp/salvador && \
    make CC=gcc -C /tmp/salvador && \
    mv /tmp/salvador/salvador /opt/amiga/bin && \
    chmod 755 /opt/amiga/bin/salvador && \
    rm -rf /tmp/salvador

FROM ubuntu:24.04 AS final

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt -y install \
      vim \
      curl \
      wget \
      git \
      python3 \
      file \
      lhasa \
      libmpfr6 \
      libmpc3 \
      libgmpxx4ldbl \
      srecord \
      texinfo \
      build-essential && \
      apt clean && \
      rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/amiga /opt/amiga

ENV VBCC=/opt/amiga/m68k-amigaos/vbcc
ENV NDK32=/opt/amiga/m68k-amigaos/NDK3.2
ENV PATH=/opt/amiga/bin:/opt/amiga/venv/bin:$PATH

