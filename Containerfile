FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all packages
RUN apt-get -y update && \
    apt-get -y install \
      apt-utils curl git jlha-utils lhasa python3 python3-pip srecord wget \
      autoconf bison flex g++ gcc gettext file libgmpxx4ldbl libgmp-dev \
      libmpfr6 libmpfr-dev libmpc3 libmpc-dev libncurses-dev make rsync \
      texinfo

# Make jlha the default
RUN cd /usr/bin && mv lha lha.lhasa && ln -s jlha lha

# Install amitools.
RUN apt-get -y autoremove && \
    rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED && \
    pip3 install -U git+https://github.com/cnvogelg/amitools.git && \
    pip3 install machine68k

# Install Bebbo's amiga-gcc
RUN git config --global pull.rebase false && \
    cd /root && \
    git clone --depth 1 https://github.com/AmigaPorts/m68k-amigaos-gcc amiga-gcc && \
    cd /root/amiga-gcc && \
    mkdir -p /opt/amiga && \
    make update && \
    make -j4 all vlink vbcc && \
    cd / && \
    rm -rf /root/amiga-gcc

# Install a working VBCC
RUN mkdir -p /tmp/vbcc-targets && \
    curl -o /tmp/vbcc-targets/vbcc_target_m68k-amigaos.lha http://phoenix.owl.de/vbcc/2022-05-22/vbcc_target_m68k-amigaos.lha && \
    cd /tmp/vbcc-targets && \
    lha -x vbcc_target_m68k-amigaos.lha && \
    mv /tmp/vbcc-targets/vbcc_target_m68k-amigaos/targets /opt/amiga/m68k-amigaos/vbcc/ && \
    cd - && \
    mkdir -p /tmp/vbcc-unix-configs && \
    curl -o /tmp/vbcc-unix-configs/vbcc_unix_config.tar.gz http://phoenix.owl.de/vbcc/2022-02-28/vbcc_unix_config.tar.gz && \
    tar -xvf /tmp/vbcc-unix-configs/vbcc_unix_config.tar.gz -C /tmp/vbcc-unix-configs && \
    mv /tmp/vbcc-unix-configs/config /opt/amiga/m68k-amigaos/vbcc/ && \
    rm -rf /tmp/vbcc-targets /tmp/vbcc-unix-configs

# Clean up
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y \
      libgmp-dev libmpfr-dev libmpc-dev libncurses-dev rsync texinfo && \
    apt-get -y autoremove

ENV VBCC=/opt/amiga/m68k-amigaos/vbcc
ENV PATH=/opt/amiga/bin:$PATH

