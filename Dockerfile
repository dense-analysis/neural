FROM testbed/vim:24 AS build-vim

# Install tools for Vim testing.
# We have a layer here so we rebuild Vim and Neovim less frequently.
# Installing the Vim versions is the slowest build step.
RUN install_vim -tag v8.0.0027 -build \
                -tag v9.0.0297 -build \
                -tag neovim:v0.8.0 -build

RUN apk --update add git \
    && git clone https://github.com/junegunn/vader.vim /vader \
    && cd /vader \
    && git checkout c6243dd81c98350df4dec608fa972df98fa2a3af

FROM python:3.10-alpine

# Copy shared libraries needed for Neovim.
COPY --from=build-vim /usr/lib/libluv.so.* /usr/lib/
COPY --from=build-vim /usr/lib/libuv.so.* /usr/lib/
COPY --from=build-vim /usr/lib/libmsgpackc.so.* /usr/lib/
COPY --from=build-vim /usr/lib/libtermkey.so.* /usr/lib/
COPY --from=build-vim /usr/lib/libunibilium.so.* /usr/lib/
COPY --from=build-vim /usr/lib/libluajit-5.1.so.* /usr/lib/
COPY --from=build-vim /usr/lib/lua /usr/lib/lua
COPY --from=build-vim /vim-build /vim-build
COPY --from=build-vim /vader /vader

# Install scripting tools for test scripts.
# We need nodejs for running pyright.
ENV PACKAGES="\
    bash \
    grep \
    sed \
    nodejs \
"
RUN apk --update add $PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Switch to the /root dir for setting up the project.
WORKDIR /root

# Install setuptools and uv for Python
RUN pip install uv

# Sync dependencies and install the Python dependencies we need.
# vim-vint is included here for running the Vim lint steps.
# We have a layer here that's very fast.
COPY pyproject.toml uv.lock /root/
RUN uv sync --locked --no-install-project

ARG GIT_VERSION
LABEL Version=${GIT_VERSION}
LABEL Name=denseanalysis/neural
