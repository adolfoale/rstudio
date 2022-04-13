FROM adolfoale/rstudio:jupyter-base

USER 0

ENV R_VERSION=4.1.3
ENV TERM=xterm
ENV R_HOME=/usr/local/lib/R
ENV TZ=Etc/UTC

RUN sed -i 's/# deb-src http:\/\/archive.ubuntu.com\/ubuntu\/ focal universe/deb-src http:\/\/archive.ubuntu.com\/ubuntu\/ focal universe/g' /etc/apt/sources.list
RUN mkdir /rocker_scripts
COPY scripts/* /rocker_scripts/

RUN /rocker_scripts/install_R_source.sh

ENV CRAN=https://packagemanager.rstudio.com/cran/__linux__/focal/latest
ENV LANG=en_US.UTF-8

COPY scripts /rocker_scripts

RUN /rocker_scripts/setup_R.sh

##
COPY install.R /opt/

RUN R CMD javareconf && \
    apt-get update && \
    apt-get install -y libzmq3-dev \
      libssl-dev \
      libcurl4-openssl-dev \
      libxml2-dev && \
    ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.64.2 /usr/lib/x86_64-linux-gnu/libicui18n.so.64 && \
    ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.64.2 /usr/lib/x86_64-linux-gnu/libicui18n.so

#RUN Rscript /opt/install.R --save
RUN chown -R efx_container_user /usr/local/lib/R/ && \
    Rscript -e "installed.packages()" > /opt/installed.packages.txt && \
    cat /opt/installed.packages.txt

USER 1000

