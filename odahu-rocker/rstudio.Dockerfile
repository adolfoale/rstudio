FROM adolfoale/rstudio:r-base

#ENV RSTUDIO_VERSION=2022.02.1+461

USER 0

RUN apt update && apt install -y git wget

RUN cd /opt && git clone https://github.com/rstudio/rstudio.git
#    cd rstudio && git checkout tags/v$RSTUDIO_VERSION

RUN cd /opt/rstudio/dependencies/linux/ && \
    ./install-dependencies-focal --exclude-qt-sdk

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

# install aditional R packages
RUN Rscript -e 'install.packages("Hmisc", repos="https://packagemanager.rstudio.com/cran/__linux__/focal/latest/")'

COPY nexus.sources.list /etc/apt/sources.list
COPY partner.list /etc/apt/sources.list.d/
RUN rm -f /etc/apt/sources.list.d/openjdk-r-ubuntu-ppa-focal.list 

USER 1000
