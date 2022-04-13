FROM odahu:r-base

USER 0

ENV RSTUDIO_VERSION=1.2.5033

RUN mkdir -p /opt/r-studio

RUN apt update && apt install -y wget

# install libssl1.0-dev
RUN echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list.d/libssl1.0-dev.list && \
    apt update && apt-cache policy libssl1.0-dev && \
    apt-get install -y libssl1.0-dev && \
    rm /etc/apt/sources.list.d/libssl1.0-dev.list

RUN wget -O /opt/rstudio.tar.gz https://github.com/rstudio/rstudio/archive/v$RSTUDIO_VERSION.tar.gz

RUN tar -xzvf /opt/rstudio.tar.gz -C /opt/r-studio

RUN apt-get update && cd /opt/r-studio/*/dependencies/linux/ && ./install-dependencies-debian --exclude-qt-sdk

RUN apt-get install -y gfortran libreadline-dev libxt-dev liblzma-dev

RUN cd /opt/r-studio/*/ && mkdir build && cd build  &&  \
    cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release &&  \
    make install

RUN useradd -r rstudio-server && \
     mkdir -p /var/run/rstudio-server && \
     mkdir -p /var/lock/rstudio-server && \
     mkdir -p /var/log/rstudio-server && \
     mkdir -p /var/lib/rstudio-server && \
     ln -f -s /usr/local/lib/rstudio-server/bin/rserver /usr/sbin/rserver && \
     ln -f -s /usr/local/lib/rstudio-server/bin/rsession /usr/sbin/rsession && \
     cp /usr/local/lib/R/lib/*.so /usr/lib && \
     mkdir -p /etc/rstudio && \
     touch /etc/rstudio/repos.conf

USER 1000
