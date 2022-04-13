FROM adolfoale/rstudio:r-base

ENV RSTUDIO_VERSION=1.4.1717

USER 0

RUN apt update && apt install -y git wget

# install libssl1.0-dev
#RUN echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list.d/libssl1.0-dev.list && \
#    apt update && apt-cache policy libssl1.0-dev && \
#    apt-get install -y libssl1.0-dev && \
#    rm /etc/apt/sources.list.d/libssl1.0-dev.list

RUN cd /opt && git clone https://github.com/rstudio/rstudio.git && \
    cd rstudio && git checkout tags/v$RSTUDIO_VERSION

RUN cd /opt/rstudio/dependencies/linux/ && \
    ./install-dependencies-debian --exclude-qt-sdk

RUN mkdir /opt/rstudio/build && \
    cd /opt/rstudio/build && \
    cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release && \
    make install

RUN useradd -r rstudio-server

RUN mkdir -p /var/run/rstudio-server && \
    mkdir -p /var/lock/rstudio-server && \
    mkdir -p /var/log/rstudio-server && \
    mkdir -p /var/lib/rstudio-server

RUN ln -f -s /usr/local/bin/rstudio-server /usr/sbin/rserver && \
    ln -f -s /usr/local/bin/rsession /usr/sbin/rsession

RUN cp /usr/local/lib/R/lib/*.so /usr/lib && \
    mkdir -p /etc/rstudio && \
    touch /etc/rstudio/repos.conf

USER 1000
