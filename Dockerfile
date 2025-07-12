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
ENV PATH=/root/.pyenv/shims:/root/.pyenv/bin:$PATH

# Switch to the /root dir copy the .python-version from the project.
WORKDIR /root

# Install tools for Vim testing.
# We have a layer here so we rebuild Vim and Neovim less frequently.
# Installing the Vim versions is the slowest build step.
RUN install_vim -tag v8.0.0027 -build \
                -tag v9.0.0297 -build \
                -tag neovim:v0.8.0 -build
RUN git clone https://github.com/junegunn/vader.vim vader && \
    cd vader && git checkout c6243dd81c98350df4dec608fa972df98fa2a3af

# Copy project files into the project for dependencies and such.
COPY .python-version /root/

# Install the Python version we need with uv.
# We have a layer here so we rebuild Python and install uv less frequently.
# Installing Python with uv is slower than updating dependencies, but much
# faster than installing the Vim and Neovim versions.
RUN curl https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash \
    && eval "$(pyenv init -)" \
    && eval "$(pyenv virtualenv-init -)" \
    && pyenv install \
    && pip install uv

# Sync dependencies and install the Python dependencies we need.
# vim-vint is included here for running the Vim lint steps.
# We have a layer here that's very fast.
COPY pyproject.toml uv.lock /root/
RUN uv sync --locked --no-install-project

ARG GIT_VERSION
LABEL Version=${GIT_VERSION}
LABEL Name=denseanalysis/neural
