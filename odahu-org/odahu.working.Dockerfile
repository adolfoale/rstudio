FROM ubuntu:focal
#[ -z "$(apt-get indextargets)" ]

RUN set -xe   && echo '#!/bin/sh' > /usr/sbin/policy-rc.d  && echo 'exit 101' >> /usr/sbin/policy-rc.d  && chmod +x /usr/sbin/policy-rc.d   && dpkg-divert --local --rename --add /sbin/initctl  && cp -a /usr/sbin/policy-rc.d /sbin/initctl  && sed -i 's/^exit.*/exit 0/' /sbin/initctl   && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup   && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean  && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean  && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean   && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages   && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes   && echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

RUN mkdir -p /run/systemd && echo 'docker' > /run/systemd/container

CMD ["/bin/bash"]

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

ARG NB_USER=efx_container_user
ARG NB_UID=1000
ARG NB_GID=100

USER root

ENV DEBIAN_FRONTEND=noninteractive

ENV NB_GID=100 NB_UID=1000 NB_USER=efx_container_user 

RUN apt-get update  && apt-get install -yq --no-install-recommends     wget     bzip2     ca-certificates     sudo     locales     fonts-liberation     run-one  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV NB_GID=100 NB_UID=1000 NB_USER=efx_container_user 

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen &&     locale-gen

ENV CONDA_DIR=/opt/conda SHELL=/bin/bash NB_USER=efx_container_user NB_UID=1000 NB_GID=100 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/home/efx_container_user

COPY fix-permissions /usr/local/bin/fix-permissions 
COPY start-notebook.sh /usr/local/bin/
COPY start.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/

RUN chmod a+rx /usr/local/bin/fix-permissions

RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su &&     sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers &&     sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers &&     useradd -m -s /bin/bash -N -u $NB_UID $NB_USER &&     mkdir -p $CONDA_DIR &&     chown $NB_USER:$NB_GID $CONDA_DIR &&     chmod g+w /etc/passwd &&     fix-permissions $HOME &&     fix-permissions "$(dirname $CONDA_DIR)"

USER 1000

WORKDIR /home/efx_container_user

ARG PYTHON_VERSION=default

RUN mkdir /home/$NB_USER/work &&     fix-permissions /home/$NB_USER

ENV MINICONDA_VERSION=4.7.12.1 MINICONDA_MD5=81c773ff87af5cfac79ab862942ab6b3 CONDA_VERSION=4.7.12

RUN cd /tmp &&     wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh &&     echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - &&     /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR &&     rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh &&     echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned &&     conda config --system --prepend channels conda-forge &&     conda config --system --set auto_update_conda false &&     conda config --system --set show_channel_urls true &&     conda config --system --set channel_priority strict &&     if [ ! $PYTHON_VERSION='default' ]; then conda install --yes python=$PYTHON_VERSION; fi &&     conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned &&     conda install --quiet --yes conda &&     conda install --quiet --yes pip &&     conda update --all --quiet --yes &&     conda clean --all -f -y &&     rm -rf /home/$NB_USER/.cache/yarn &&     fix-permissions $CONDA_DIR &&     fix-permissions /home/$NB_USER

RUN conda install --quiet --yes 'tini=0.18.0' &&     conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned &&     conda clean --all -f -y &&     fix-permissions $CONDA_DIR &&     fix-permissions /home/$NB_USER

RUN conda install --quiet --yes     'notebook=6.0.3'     'jupyterhub=1.1.0'     'jupyterlab=1.2.5' &&     conda clean --all -f -y &&     npm cache clean --force &&     jupyter notebook --generate-config &&     rm -rf $CONDA_DIR/share/jupyter/lab/staging &&     rm -rf /home/$NB_USER/.cache/yarn &&     fix-permissions $CONDA_DIR &&     fix-permissions /home/$NB_USER

EXPOSE 8888
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

COPY jupyter_notebook_config.py /etc/jupyter/

USER root

RUN fix-permissions /etc/jupyter/

USER 1000

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

USER root

RUN apt-get update && apt-get install -yq --no-install-recommends     build-essential     emacs     git     inkscape     jed     libsm6     libxext-dev     libxrender1     lmodern     netcat     python-dev     texlive-xetex     texlive-fonts-recommended     texlive-fonts-extra     tzdata     unzip     nano     && apt-get clean && rm -rf /var/lib/apt/lists/*

USER 1000

ARG RSTUDIO_VERSION
ARG R_VERSION

USER 0

COPY dependencies.tar /opt/
RUN cd /opt/ && tar -xf dependencies.tar
RUN cd /opt/dependencies/linux/ && ./install-dependencies-debian --exclude-qt-sdk

#ENV RSTUDIO_VERSION=1.2.5033 R_VERSION=3.6.3
ENV RSTUDIO_VERSION=1.4.1717-3 R_VERSION=4.0.0

RUN mkdir -p /opt/r-studio && mkdir -p /opt/r-lang
#RUN wget -O /opt/rstudio.tar.gz https://github.com/rstudio/rstudio/archive/v$RSTUDIO_VERSION.tar.gz
RUN wget -O /opt/rstudio.tar.gz https://download1.rstudio.org/desktop/bionic/amd64/rstudio-$RSTUDIO_VERSION-amd64-debian.tar.gz
#RUN wget -O /opt/R.tar.gz https://cran.r-project.org/src/base/R-3/R-$R_VERSION.tar.gz
RUN wget -O /opt/R.tar.gz https://cran.r-project.org/src/base/R-4/R-$R_VERSION.tar.gz
RUN tar -xf /opt/rstudio.tar.gz -C /opt/r-studio
RUN tar -xf /opt/R.tar.gz -C /opt/r-lang    
RUN apt-get update && cd /opt/r-studio/resources/dependencies/ && ./install-dependencies-debian --exclude-qt-sdk
RUN apt-get install -y gfortran libreadline-dev libxt-dev liblzma-dev openjdk-8-jdk &&  update-java-alternatives -s java-1.8.0-openjdk-amd64 &&  cd /opt/r-lang/*/ &&  ln -s /lib/x86_64-linux-gnu/libreadline.so.7 /lib/x86_64-linux-gnu/libreadline.so.8
RUN LDFLAGS='-L/opt/conda/lib -licui18n -licuuc -licudata' ./configure --enable-R-shlib=yes --with-blas --with-lapack
RUN make
RUN make install
RUN cd /opt/r-studio/*/ && mkdir build && cd build  &&  cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release &&  make install
RUN useradd -r rstudio-server &&     mkdir -p /var/run/rstudio-server &&     mkdir -p /var/lock/rstudio-server &&     mkdir -p /var/log/rstudio-server &&     mkdir -p /var/lib/rstudio-server && ln -f -s /usr/local/lib/rstudio-server/bin/rserver /usr/sbin/rserver && ln -f -s /usr/local/lib/rstudio-server/bin/rsession /usr/sbin/rsession && cp /usr/local/lib/R/lib/*.so /usr/lib && mkdir -p /etc/rstudio && touch /etc/rstudio/repos.conf

COPY install.R /opt/

RUN R CMD javareconf && apt-get update && apt-get install -y libzmq3-dev libssl-dev libcurl4-openssl-dev libxml2-dev &&  ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.64.2 /usr/lib/x86_64-linux-gnu/libicui18n.so.64 && ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.64.2 /usr/lib/x86_64-linux-gnu/libicui18n.so
#RUN Rscript /opt/install.R --save
RUN chown -R efx_container_user /usr/local/lib/R/ && Rscript -e "installed.packages()" > /opt/installed.packages.txt && cat /opt/installed.packages.txt

USER 1000
