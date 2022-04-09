# Minimal notebook 

FROM adolfoale/rstudio:minimal-notebook

USER 0

# install some help packages
RUN apt update -qq && apt install -y --no-install-recommends software-properties-common dirmngr wget net-tools

# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# Fingerprint: 298A3A825C0D65DFD57CBB651716619E084DAB9
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# install r-base
RUN apt install -y --no-install-recommends r-base

# Get 5000+ CRAN Packages
RUN echo "\n" | add-apt-repository ppa:c2d4u.team/c2d4u4.0+
RUN apt install -y --no-install-recommends r-cran-rstan

# RStudio Server for Debian & Ubuntu
RUN apt-get install -y gdebi-core
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2022.02.0-443-amd64.deb
RUN echo "y\n" | gdebi rstudio-server-2022.02.0-443-amd64.deb


# install java
RUN apt update && apt install -y default-jre default-jdk build-essential cmake && java -version

# odahu-rstudio/datascience.Dockerfile
COPY install.R /opt/

RUN R CMD javareconf && \
    apt-get update && apt-get install -y libzmq3-dev libssl-dev libcurl4-openssl-dev libxml2-dev && \
    ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.64.2 /usr/lib/x86_64-linux-gnu/libicui18n.so.64 && \
    ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.64.2 /usr/lib/x86_64-linux-gnu/libicui18n.so && \
    Rscript /opt/install.R --save && \
    chown -R efx_container_user /usr/local/lib/R/ && \
    Rscript -e "installed.packages()" > /opt/installed.packages.txt && \
    cat /opt/installed.packages.txt

USER 1000
