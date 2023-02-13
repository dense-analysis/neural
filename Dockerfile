FROM testbed/vim:24

# Add packages we need.
#
# We need most packages for installing Python.
# We need nodejs for pyright.
ENV PACKAGES="\
    bash \
    curl \
    git \
    build-base \
    patch \
    zlib-dev \
    libffi-dev \
    linux-headers \
    readline-dev \
    openssl \
    nodejs \
    openssl-dev \
    sqlite-dev \
    bzip2-dev \
    python3 \
    py3-pip \
    grep \
    sed \
"
RUN apk --update add $PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Install tools for Python testing.
ENV PATH /root/.pyenv/shims:/root/.pyenv/bin:$PATH
# We need --ignore-installed to ignore the `packaging` package version.
RUN pip install --ignore-installed tox==4.4.5
RUN curl https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash \
    && eval "$(pyenv init -)" \
    && eval "$(pyenv virtualenv-init -)" \
    && pyenv install 3.7 \
    && pyenv install 3.10 \
    && ln -s /root/.pyenv/versions/3.7.*/bin/python3.7 /root/.pyenv/bin/python3.7 \
    && ln -s /root/.pyenv/versions/3.10.*/bin/python3.10 /root/.pyenv/bin/python3.10

# Install tools for Vim testing.
RUN install_vim -tag v8.0.0027 -build \
                -tag v9.0.0297 -build \
                -tag neovim:v0.8.0 -build
# Install vint with Python 3.10 to avoid `packaging` issues.
RUN python3.10 -m pip install vim-vint==0.3.21
RUN git clone https://github.com/junegunn/vader.vim vader && \
    cd vader && git checkout c6243dd81c98350df4dec608fa972df98fa2a3af

ARG GIT_VERSION
LABEL Version=${GIT_VERSION}
LABEL Name=denseanalysis/neural
