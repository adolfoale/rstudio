FROM odahu:r-base

USER 0

RUN apt update && apt install -y git wget

RUN cd /opt && wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.4.1717-amd64-debian.tar.gz
    tar -xvzf rstudio.tar.gz && \
    mv /opt/rstudio-1.3.1093/ /opt/r-studio/ && \
    cd /opt/r-studio/dependencies/linux/ && \
    ./install-dependencies-bionic --exclude-qt-sdk

RUN mkdir /opt/r-studio/build && \
    cd /opt/r-studio/build && \
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
