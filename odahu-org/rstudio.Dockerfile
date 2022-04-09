FROM adolfoale/rstudio:odahu-jupyterstack-ubuntu20

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
RUN apt update && apt install -y --no-install-recommends r-base

# Get 5000+ CRAN Packages
RUN echo "\n" | add-apt-repository ppa:c2d4u.team/c2d4u4.0+
RUN apt update && apt install -y --no-install-recommends r-cran-rstan

# RStudio Server for Debian & Ubuntu
RUN apt-get install -y gdebi-core
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2022.02.0-443-amd64.deb
RUN echo "y\n" | gdebi rstudio-server-2022.02.0-443-amd64.deb


# install java
RUN apt update && apt install -y default-jre default-jdk build-essential cmake && java -version

# odahu-rstudio/datascience.Dockerfile
COPY install.R /opt/

#RUN Rscript /opt/install.R --save && \
#    Rscript -e "installed.packages()" > /opt/installed.packages.txt && \
#    cat /opt/installed.packages.txt

USER 1000
