# syntax=docker/dockerfile:latest

FROM alpine:latest AS build

# Set app name
ENV APP_NAME="mpnetwork"

# Set build ENV
ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV:-test}
# assuming these are all already in your ENV of your project directory, perhaps via direnv and an .envrc file...
# you can rebuild everything with this: (add --no-cache if you want a full rebuild)
# docker build --progress=plain -t mpnetwork \
#   --target=$MIX_ENV \
#   --build-arg USER \
#   --build-arg APP_NAME \
#   --build-arg MIX_ENV \
#   --build-arg SECRET_KEY_BASE \
#   --build-arg LIVE_VIEW_SIGNING_SALT \
#   --build-arg SPARKPOST_API_KEY \
#   --build-arg FQDN \
#   --build-arg STATIC_URL \
#   --build-arg LOGFLARE_API_KEY \
#   --build-arg LOGFLARE_DRAIN_ID \
#   --build-arg POSTGRES_PASSWORD \
#   --build-arg DATABASE_URL \
#   --build-arg TEST_DATABASE_URL \
#   --build-arg OBAN_WEB_LICENSE_KEY \
#   .
ARG APP_NAME
ENV APP_NAME=${APP_NAME:-mpnetwork}
ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV:-dev}
ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE:-0000000000000000000000000000000000000000000000000000000000000000}
ARG LIVE_VIEW_SIGNING_SALT
ENV LIVE_VIEW_SIGNING_SALT=${LIVE_VIEW_SIGNING_SALT:-000000000000000000000000000000}
ARG SPARKPOST_API_KEY
ENV SPARKPOST_API_KEY=${SPARKPOST_API_KEY:-0000000000000000000000000000000000000000}
ARG FQDN
ENV FQDN=${FQDN:-localhost}
ARG STATIC_URL
ENV STATIC_URL=${STATIC_URL:-localhost}
ARG LOGFLARE_API_KEY
ENV LOGFLARE_API_KEY=${LOGFLARE_API_KEY:-000000000000}
ARG LOGFLARE_DRAIN_ID
ENV LOGFLARE_DRAIN_ID=${LOGFLARE_DRAIN_ID:-00000000-0000-0000-0000-000000000000}
ARG POSTGRES_PASSWORD
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL:-ecto://postgres:${POSTGRES_PASSWORD}@localhost:5432/${APP_NAME}_dev}
ARG TEST_DATABASE_URL
ENV TEST_DATABASE_URL=${TEST_DATABASE_URL:-ecto://postgres:${POSTGRES_PASSWORD}@localhost:5432/${APP_NAME}_test}
ARG OBAN_WEB_LICENSE_KEY
ENV OBAN_WEB_LICENSE_KEY=${OBAN_WEB_LICENSE_KEY:-00000000000000000000000000000000}

# Add underprivileged non-root user to run the app or log in as.
# I set the uid and gid to the same as my $USER's in my current host (WSL2)
# This will at least solve the most typical permissions issues you'd get with bind-mounted volumes (-v arg to the "docker run" command)
# You may want to get more sophisticated with this in the future:
# https://docs.docker.com/engine/security/userns-remap/
# In the test and dev targets, this user will be added to the sudo group and given a password
# but ONLY in those targets
ARG USER
ENV USER=${USER:-elixirdev}
ENV UID=1000
ENV GID=1000
RUN addgroup -S -g ${GID} ${USER} && \
    adduser --disabled-password --home /home/${USER} -S -G ${USER} -s /bin/zsh -u ${UID} ${USER}
ENV HOME=/home/${USER}

# USER root
# Configure locale, which is a mess and defaults to latin1, which is just... NO
# Taken from https://grrr.tech/posts/2020/add-locales-to-alpine-linux-docker-image/
ENV LANG=en_US.UTF-8 MUSL_LOCALE_DEPS="cmake make musl-dev gcc gettext-dev libintl" MUSL_LOCPATH="/usr/share/i18n/locales/musl"
RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
      && cd musl-locales-master \
      && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
      && cd .. && rm -r musl-locales-master

# ARG VIPS_VERSION=8.10.5
# ARG VIPS_URL=https://github.com/libvips/libvips/releases/download

# Install libvips, build dependencies
# python was originally included, no idea why, removed it
# RUN set -x -o pipefail \
#     && wget -O- ${VIPS_URL}/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar xzC /tmp \
#     && apk update \
#     && apk upgrade \
#     && apk add \
#     git curl build-base zlib libxml2 glib gobject-introspection \
#     libjpeg-turbo libexif lcms2 fftw giflib libpng \
#     libwebp orc tiff poppler-glib librsvg libgsf openexr \
#     libheif libimagequant pango \
#     && apk add --virtual vips-dependencies \
#     zlib-dev libxml2-dev glib-dev gobject-introspection-dev \
#     libjpeg-turbo-dev libexif-dev lcms2-dev fftw-dev giflib-dev libpng-dev \
#     libwebp-dev orc-dev tiff-dev poppler-dev librsvg-dev libgsf-dev openexr-dev \
#     libheif-dev libimagequant-dev pango-dev \
#     py-gobject3-dev \
#     && cd /tmp/vips-${VIPS_VERSION} \
#     && ./configure --prefix=/usr \
#                    --disable-static \
#                    --disable-dependency-tracking \
#                    --enable-silent-rules \
#     && make --jobs=8 -s install-strip \
#     && cd $OLDPWD \
#     && rm -rf /tmp/vips-${VIPS_VERSION} \
#     && apk del --purge vips-dependencies \
#     && rm -rf /var/cache/apk/*

# add vips-dev and deps
RUN set -x -o pipefail \
 && apk add --no-cache alpine-sdk \
 && apk add --no-cache \
    git curl build-base clang zlib libxml2 glib gobject-introspection \
    libjpeg-turbo libexif lcms2 fftw giflib libpng \
    libwebp orc tiff poppler-glib librsvg libgsf openexr \
    libheif libimagequant pango \
 && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community --repository http://dl-3.alpinelinux.org/alpine/edge/main vips-dev

# Install psql and bash via apk
# perl, autoconf needed to compile erlang for some reason
RUN apk add --no-cache postgresql-client bash perl autoconf gnupg ncurses-dev ncurses-terminfo m4 

# make sure psql is there (sanity check)
RUN psql --version

# do the rest as unprivileged user
USER ${USER}:${USER}

# install asdf in order to get elixir/erlang/nodejs lined up with .tool-versions
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf
RUN echo -e '\nsource $HOME/.asdf/asdf.sh' >> $HOME/.zshrc
ENV PATH=$HOME/.asdf/bin:$PATH

WORKDIR ${HOME}

# now install asdf plugins and deps (note: make sure postgres is NOT included here!)
COPY --chown=${USER}:${USER} bin/asdf-install-plugins ${HOME}/
COPY --chown=${USER}:${USER} bin/asdf-install-versions ${HOME}/
COPY --chown=${USER}:${USER} .tool-versions ${HOME}/
RUN ls -al
RUN ["bash", "asdf-install-plugins"]
RUN ["bash", "asdf-install-versions"]

# Create mountpoint (or future app dir if prod)
RUN mkdir /app

# Install Rust
# RUN apk add --no-cache rust cargo
# Use rustup and default to nightly for now
# RUN curl -sSf sh.rustup.rs | sh -s -- -y --default-toolchain nightly
# RUN (curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly) && source $HOME/.cargo/env && rustup default nightly
# ENV PATH="$HOME/.cargo/bin:$PATH"

# Add Rust and configure
# So apparently dynamically-linked crates won't compile correctly on musl toolchains (as in alpine)
# so we will force static compilation.
# Additionally, we will do this as the underprivileged user,
# otherwise elixir/erlang have issues compiling lvips in userspace
ENV RUSTFLAGS="-C target-feature=-crt-static"
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --default-toolchain nightly
# Rustup should hopefully modify PATH appropriately, otherwise: EDIT Aaaaand nope, it didn't, so
ENV PATH=/home/$USER/.cargo/bin:$PATH
RUN mkdir /home/${USER}/bin
# add home/bin to PATH... but add it at the end so this user can't override any builtins
ENV PATH=$PATH:/home/${USER}/bin

# Install Trivy vulnerability scanner
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /home/${USER}/bin

# RUN apk add --no-cache \
#         gcc \
#         build-base \
#         npm \
#         git \
#         autoconf \
#         automake \
#         clang \
#         curl \
#         expat-dev \
#         gettext \
#         giflib-dev \
#         git \
#         glib-dev \
#         gvfs \
#         gobject-introspection \
#         libexif-dev \
#         libheif-dev \
#         libjpeg-turbo-dev \
#         libpng-dev \
#         libtool \
#         libwebp-dev \
#         libxml2-dev \
#         llvm \
#         musl-dev \
#         pngquant \
#         swig \
#         wget \
#         elixir


# RUN wget ${VIPS_URL}/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz \
#   && tar xzf vips-${VIPS_VERSION}.tar.gz \
#   && cd vips-${VIPS_VERSION} \
#   && ./configure --prefix=$VIPS_PREFIX \
#   && make V=0 \
#   && make install

# clean the build area ready for packaging
# RUN cd $VIPS_PREFIX \
#   && rm bin/batch_* bin/vips-* \
#   && rm bin/vipsprofile bin/light_correct bin/shrink_width \
#   && strip lib/*.a lib/lib*.so* \
#   && rm -rf share/gtk-doc \
#   && rm -rf share/man \
#   && rm -rf share/thumbnailers

#RUN cd $VIPS_PREFIX \
#  && rm -rf build
#  && mkdir build \
#  && tar czf build/libvips.tar.gz bin include lib

##### TEST TARGET #####
FROM build AS test

# don't need to copy anything, working directory bind-mounted
# COPY . .

# bind mount will be to /app from cwd
WORKDIR /app

COPY --chown=$USER:$USER . .

RUN mix local.hex --force && \
  mix hex.organization auth oban --key ${OBAN_WEB_LICENSE_KEY} && \
  mix deps.get --force && \
  mix local.rebar --force && \
  mix deps.compile

CMD ["mix", "test"]

##### DEV TARGET #####
FROM build AS dev

USER root:root

# the port we serve from
EXPOSE 4000

RUN chown ${USER}:${USER} /app

# add common dev-only tooling
RUN apk add --no-cache git curl zsh bash inotify-tools
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing direnv

# Install python/pip
# EDIT: Nope, removed. Python sucks anyway. (So does Go, but... yeah...)
# ENV PYTHONUNBUFFERED=1
# RUN apk add --no-cache python3 && ln -sf python3 /usr/bin/python
# RUN python3 -m ensurepip
# RUN pip3 install --no-cache --upgrade pip setuptools
# # the above leaves a bunch of shite in tmp that I don't want to make part of my image
# RUN rm -rf /tmp/*
# # yeah, I have no idea which version this actually installs so...
# ENV PYTHONPATH=/usr/lib/python3.7/site-packages:/usr/lib/python3.8/site-packages:/usr/lib/python3.9/site-packages

USER ${USER}:${USER}
ENV SHELL=/bin/zsh

WORKDIR /home/${USER}

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Add zsh because it's about time and it's awesome
# RUN apk add --no-cache zsh # Nope, let's use prezto's method:
# EDIT: Commented all this out and just bind-mounted my WSL2 home directory to the container's home directory instead
# RUN git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto
# RUN setopt EXTENDED_GLOB && \
#     for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do \
#       ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"; \
#     done
# we will mount the working directory to /app
WORKDIR /app

# needed to prevent zsh from firing up an intro wizard Every. Single. Time.
# edit: not anymore
# RUN echo "#placeholder" > .zshrc

CMD ["zsh"]

# prepare release image
##### PROD TARGET #####
FROM alpine:latest AS prod

EXPOSE 80 443

ENV APP_NAME="mpnetwork"

RUN apk add --no-cache openssl ncurses-libs

# Copy system binaries from build that we need to run npm and other things
COPY --from=build --chown=nobody:nobody /usr /usr

# COPY --from=build /usr/local /usr/local

# COPY --from=build /usr/bin /usr/bin

# COPY --from=build /usr/lib /usr/lib

# COPY --from=build /usr/include /usr/include

# COPY --from=build /usr/share /usr/share

# Prepare build dir
WORKDIR /app

# Build javascript assets
# I run this before the mix deps install because it changes less frequently in this project,
# and will thus get retrieved from cache more often
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY VERSION VERSION

RUN mix hex.organization auth oban --key ${OBAN_WEB_LICENSE_KEY}
RUN mix do deps.get, deps.compile
RUN mix phx.digest

# Scan for local vulnerabilities with Trivy
# I can't seem to echo or cat the stdout of this command, so commenting out for now
# RUN echo $(trivy fs /)

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists... may not need anyway?
COPY rel rel
# run the test suite first to make sure things are up to snuff
# separate out the compilation in case it is successful but the test fails,
# so that you don't need to keep recompiling just to rerun the test.
# RUN MIX_ENV=test mix do deps.compile, compile
# RUN echo $TEST_DATABASE_URL
# RUN mix test
RUN mix do compile, release --overwrite

COPY --chown=nobody:nobody /app/_build/prod/rel/${APP_NAME:-APP_NAME_env_missing} ./
# COPY --chown=nobody:nobody /app/_build/prod/lib/$APP_NAME ./

RUN chown nobody:nobody /app

USER nobody:nobody

ENV HOME=/app

CMD ["bin/$APP_NAME", "start"]

HEALTHCHECK --interval=1m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
