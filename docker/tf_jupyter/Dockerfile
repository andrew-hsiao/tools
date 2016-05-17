FROM nvidia/cuda:7.5-cudnn4-devel

MAINTAINER Andrew Hsiao <hsiao.andrew@gmail.com>

RUN apt-get update && apt-get install -y \
        build-essential \
        curl \
        git \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python-dev \
        python-numpy \
        python-pip \
        software-properties-common \
        swig \
        zip \
        zlib1g-dev \
######################################################################################################################
# >> Install language pack
######################################################################################################################
        language-pack-en \
        language-pack-zh* \
######################################################################################################################
# << Install language pack
######################################################################################################################
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        && \
    python -m ipykernel.kernelspec

# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /

# Set up Bazel.

# We need to add a custom PPA to pick up JDK8, since trusty doesn't
# have an openjdk8 backport.  openjdk-r is maintained by a reliable contributor:
# Matthias Klose (https://launchpad.net/~doko).  It will do until
# we either update the base image beyond 14.04 or openjdk-8 is
# finally backported to trusty; see e.g.
#   https://bugs.launchpad.net/trusty-backports/+bug/1368094
RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk openjdk-8-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
RUN echo "startup --batch" >>/root/.bazelrc
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/root/.bazelrc
ENV BAZELRC /root/.bazelrc
# Install the most recent bazel release.
ENV BAZEL_VERSION 0.2.1
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE.txt && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.
######################################################################################################################
# >> Tensorflow source code & enter serving workdir
######################################################################################################################
RUN git clone --recurse-submodules https://github.com/tensorflow/serving.git && \
    git clone --recurse-submodules https://github.com/tensorflow/tensorflow.git && \
    git clone --recurse-submodules https://github.com/tensorflow/models.git && \
    git clone --recurse-submodules https://github.com/tensorflow/skflow.git && \
    git clone --recurse-submodules https://github.com/tensorflow/magenta.git && \
    git clone --recurse-submodules https://github.com/tensorflow/playground.git && \
    cd /serving/tensorflow && \
    git checkout r0.8

WORKDIR /serving/tensorflow
######################################################################################################################
# << Tensorflow source code & enter serving workdir
######################################################################################################################


# Configure the build for our CUDA configuration.
ENV CUDA_TOOLKIT_PATH /usr/local/cuda
ENV CUDNN_INSTALL_PATH /usr/local/cuda
ENV TF_NEED_CUDA 1

RUN ./configure && \
    bazel build -c opt --config=cuda tensorflow/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
    pip install --upgrade /tmp/pip/tensorflow-*.whl
######################################################################################################################
# >> Tensorflow serving & build tensorboard
######################################################################################################################
RUN bazel build tensorflow/tensorboard:tensorboard

#WORKDIR /serving
#RUN bazel build tensorflow_serving/...
######################################################################################################################
# << Tensorflow serving & build tensorboard
######################################################################################################################

WORKDIR /root

# Set up CUDA variables
ENV CUDA_PATH /usr/local/cuda
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

RUN ["/bin/bash"]


######################################################################################################################
# Full stack of jupyter
######################################################################################################################
RUN apt-get update && apt-get install -yq --no-install-recommends \
    vim \
    jed \
    emacs \
    wget \
    ca-certificates \
    bzip2 \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    sudo \
    locales \
    libxrender1 \
    && apt-get clean

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini && \
    echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER andrew
ENV NB_UID 1000
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

#Create andrew user with UID=1000 and in the 'users' group
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p /opt/conda && \
    chown $NB_USER /opt/conda

USER $NB_USER

# Setup andrew home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local

# Install conda as andrew
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.19.0-Linux-x86_64.sh && \
    echo "9ea57c0fdf481acf89d816184f969b04bc44dea27b258c4e86b1e3a25ff26aa0 *Miniconda3-3.19.0-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash Miniconda3-3.19.0-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-3.19.0-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.19.1

# Install Jupyter notebook as andrew
RUN conda install --yes \
    'notebook=4.1*' \
    terminado \
    && conda clean -yt


USER root

# Configure container startup as root
#EXPOSE 8888
WORKDIR /home/$NB_USER/work
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start-notebook.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

# Switch back to user to avoid accidental container runs as root
USER $NB_USER

USER root

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc && apt-get clean

# Julia dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    julia \
    libnettle4 && apt-get clean

USER $NB_USER

# Install Python 3 packages
#RUN conda install --yes \
RUN conda create --yes -p $CONDA_DIR/envs/python3 python=3.5 \ 
    'ipywidgets=4.1*' \
    'pandas=0.17*' \
    'matplotlib=1.5*' \
    'scipy=0.17*' \
    'seaborn=0.7*' \
    'scikit-learn=0.17*' \
    'scikit-image=0.11*' \
    'sympy=0.7*' \
    'cython=0.23*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.23*' \
    'bokeh=0.11*' \
    'h5py=2.5*' \
    'xlrd' \
    'nbconvert' \
    'pymongo' \
    && conda clean -yt

# Install Python 2 packages
RUN conda create --yes -p $CONDA_DIR/envs/python2 python=2.7 \
    'ipython=4.1*' \
    'ipywidgets=4.1*' \
    'pandas=0.17*' \
    'matplotlib=1.5*' \
    'scipy=0.17*' \
    'seaborn=0.7*' \
    'scikit-learn=0.17*' \
    'scikit-image=0.11*' \
    'sympy=0.7*' \
    'cython=0.23*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.23*' \
    'bokeh=0.11*' \
    'h5py=2.5*' \
    'pyzmq' \
    'xlrd' \
    'nbconvert' \
    'pymongo' \
    && conda clean -yt

# R packages including IRKernel which gets installed globally.
RUN conda config --add channels r
RUN conda install --yes \
    'rpy2=2.7*' \
    'r-base=3.2*' \
    'r-irkernel=0.5*' \
    'r-plyr=1.8*' \
    'r-devtools=1.9*' \
    'r-dplyr=0.4*' \
    'r-ggplot2=1.0*' \
    'r-tidyr=0.3*' \
    'r-shiny=0.12*' \
    'r-rmarkdown=0.8*' \
    'r-forecast=5.8*' \
    'r-stringr=0.6*' \
    'r-rsqlite=1.0*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.1*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-lubridate=1.3.3*' \
    'r-tm=0.6*' \
    'r-randomforest=4.6*' && conda clean -yt

######################################################################################################################
# >> Ignore Juila
######################################################################################################################
# Install IJulia packages as user and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not 
# taking effect properly on the .local folder in the user home dir.
#RUN julia -e 'Pkg.add("IJulia")' && \
#    mv /home/$NB_USER/.local/share/jupyter/kernels/* $CONDA_DIR/share/jupyter/kernels/ && \
#    chmod -R go+rx $CONDA_DIR/share/jupyter && \
#    rm -rf /home/$NB_USER/.local/share
#RUN julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")'

######################################################################################################################
# << Ignore Juila
######################################################################################################################

USER root

RUN conda install anaconda-client

# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime.
RUN $CONDA_DIR/envs/python2/bin/python \
    $CONDA_DIR/envs/python2/bin/ipython \
    kernelspec install-self

# Switch back to user to avoid accidental container runs as root
#USER $NB_USER
######################################################################################################################
# Build & Install tensorflow for conda
######################################################################################################################
RUN /bin/bash -c "source activate python2 && \
    pip install --upgrade --ignore-installed setuptools && \
    pip install --upgrade /tmp/pip/tensorflow-*-*.whl" 
    
WORKDIR /serving/tensorflow
RUN /bin/bash -c "source activate python3 && \
    ./configure && \
    bazel build -c opt --config=cuda tensorflow/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
    pip install --upgrade --ignore-installed setuptools && \
    pip install --upgrade /tmp/pip/tensorflow-*-py3-*.whl"

#for root env
RUN pip install --upgrade --ignore-installed setuptools && \
    pip install --upgrade /tmp/pip/tensorflow-*-py3-*.whl

WORKDIR /

#USER $NB_USER


######################################################################################################################
# Install Android SDK / NDK
######################################################################################################################
RUN sudo apt-get install lib32stdc++6 lib32z1 lib32z1-dev -y

WORKDIR /tmp
RUN wget http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz && \
    tar zxvf android-sdk_r24.4.1-linux.tgz && \
    mv android-sdk-linux /opt 

RUN wget http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin && \
    chmod a+x android-ndk-r10e-linux-x86_64.bin && \
    ./android-ndk-r10e-linux-x86_64.bin && \
    mv ./android-ndk-r10e /opt && \
    rm android-ndk-r10e-linux-x86_64.bin

RUN /opt/android-sdk-linux/tools/android update sdk --no-ui -t platform-tool && \
    /opt/android-sdk-linux/tools/android update sdk --no-ui --all --filter build-tools-23.0.1 && \
    /opt/android-sdk-linux/tools/android update sdk --no-ui --all --filter android-23

RUN wget https://storage.googleapis.com/download.tensorflow.org/models/inception5h.zip -O /tmp/inception5h.zip && \
    unzip inception5h.zip -d /serving/tensorflow/tensorflow/examples/android/assets

WORKDIR /

RUN rm -rf /tmp/*
