FROM adolfoale/rstudio:golden-image
#[ -z "$(apt-get indextargets)" ]

COPY sources.list /etc/apt/sources.list

USER root

RUN set -xe && \
    echo '#!/bin/sh' > /usr/sbin/policy-rc.d  && \
    echo 'exit 101' >> /usr/sbin/policy-rc.d  && \
    chmod +x /usr/sbin/policy-rc.d && \
    dpkg-divert --local --rename --add /sbin/initctl && \
    cp -a /usr/sbin/policy-rc.d /sbin/initctl && \
    sed -i 's/^exit.*/exit 0/' /sbin/initctl && \
    echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup && \
    echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean && \
    echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean && \
    echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean   && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes && \
    echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

RUN mkdir -p /run/systemd && echo 'docker' > /run/systemd/container

CMD ["/bin/bash"]

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

ARG NB_USER=efx_container_user
ARG NB_UID=1000
ARG NB_GID=100

ENV DEBIAN_FRONTEND=noninteractive

ENV NB_GID=100 NB_UID=1000 NB_USER=efx_container_user 

RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
      wget \
      bzip2 \
      ca-certificates \
      sudo \
      locales \
      fonts-liberation \
      run-one && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV NB_GID=100 NB_UID=1000 NB_USER=efx_container_user 

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

ENV CONDA_DIR=/opt/conda SHELL=/bin/bash NB_USER=efx_container_user NB_UID=1000 NB_GID=100 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/home/efx_container_user

COPY fix-permissions /usr/local/bin/fix-permissions 
COPY start-notebook.sh /usr/local/bin/
COPY start.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/

RUN chmod a+rx /usr/local/bin/fix-permissions

RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
#   useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    usermod -g 100 $NB_USER && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions "$(dirname $CONDA_DIR)"

USER 1000

WORKDIR /home/efx_container_user

ARG PYTHON_VERSION=default

RUN mkdir /home/$NB_USER/work && fix-permissions /home/$NB_USER

ENV MINICONDA_VERSION=4.7.12.1 MINICONDA_MD5=81c773ff87af5cfac79ab862942ab6b3 CONDA_VERSION=4.7.12

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda config --system --set channel_priority strict && \
    if [ ! $PYTHON_VERSION='default' ]; then conda install --yes python=$PYTHON_VERSION; fi && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda install --quiet --yes conda && \
    conda install --quiet --yes pip && \
    conda update --all --quiet --yes && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN conda install --quiet --yes 'tini=0.18.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN conda install --quiet --yes 'notebook=6.0.3' 'jupyterhub=1.1.0' 'jupyterlab=3.2.1' && \
    conda install jupyter-server-proxy -c conda-forge && \
    conda clean --all -f -y && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

EXPOSE 8888
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

COPY jupyter_notebook_config.py /etc/jupyter/

USER root

RUN apt-get update && \
    apt-get install -yq --no-install-recommends build-essential \
      emacs \
      git \
      inkscape \
      jed \
      libsm6 \
      libxext-dev \
      libxrender1 \
      lmodern \
      netcat \
      python-dev \
      texlive-xetex \
      texlive-fonts-recommended \
      texlive-fonts-extra \
      tzdata \
      unzip \
      vim \
      default-jre \
      default-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER 1000
