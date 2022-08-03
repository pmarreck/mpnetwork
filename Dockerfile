# syntax=docker/dockerfile:latest

FROM alpine:latest AS build


# Add shells necessary to get later shell scripting to work
# And then set the shell here because otherwise the env gets reset
RUN apk add --no-cache zsh bash
SHELL ["/bin/zsh", "-c"]

# Set app name
ENV APP_NAME="mpnetwork"

USER root:root

# Set build ENV
ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV:-test}
# assuming these are all already in your ENV of your project directory, perhaps via direnv and an .envrc file...
# you can rebuild everything with this: (add --no-cache if you want a full rebuild)
# docker build --progress=plain -t mpnetwork-test \
#   --target=$MIX_ENV \
#   --build-arg BUILDKIT_INLINE_CACHE=1 \
#   --build-arg APP_USER \
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
#   --build-arg OBAN_LICENSE_KEY \
#   .

# Do a preproduction build (which also runs the test suite)
# docker build --network=host --progress=plain -t mpnetwork-prod_build \
#   --target=prod_build \
#   --build-arg BUILDKIT_INLINE_CACHE=1 \
#   --build-arg APP_USER \
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
#   --build-arg OBAN_LICENSE_KEY \
#   .

ARG APP_USER
ENV APP_USER=${APP_USER:-app}
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
ARG OBAN_LICENSE_KEY
ENV OBAN_LICENSE_KEY=${OBAN_LICENSE_KEY:-00000000000000000000000000000000}

# Add underprivileged non-root user to run the app or log in as.
# I set the uid and gid to the same as my $APP_USER's in my current host (WSL2)
# This will at least solve the most typical permissions issues you'd get with bind-mounted volumes (-v arg to the "docker run" command)
# You may want to get more sophisticated with this in the future:
# https://docs.docker.com/engine/security/userns-remap/


ENV APP_GROUP="${APP_USER}"
ENV APP_UID="1000"
ENV APP_GID="1000"
ENV SHELL="/bin/zsh"
ENV HOME="/${APP_USER}"

RUN mkdir -p "${HOME}"

# The following addgroup/adduser commands should work across both alpine and ubuntu
# Create the app group
RUN addgroup --gid ${APP_GID} ${APP_GROUP}
# Add the app user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "${HOME}" \
    --ingroup "$APP_GROUP" \
    --no-create-home \
    --uid "$APP_UID" \
    --shell "$SHELL" \
    "$APP_USER"

# User is still root
# Cause cmake to statically link
ENV CMAKE_EXE_LINKER_FLAGS="-static"
# Configure locale, which is a mess and defaults to latin1, which is just... NO
# Also add build tooling
# Taken from https://grrr.tech/posts/2020/add-locales-to-alpine-linux-docker-image/
ENV LANG=en_US.UTF-8 MUSL_LOCPATH="/usr/share/i18n/locales/musl"
RUN apk add --no-cache \
    cmake make musl-dev gcc libgcc g++ gettext-dev libintl \
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
    libheif libimagequant pango-dev \
 && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community --repository http://dl-3.alpinelinux.org/alpine/edge/main vips-dev

# Install psql and bash via apk
# perl, autoconf needed to compile erlang for some reason
# so is lksctp-tools-dev, in order to provide sctp.h (new in OTP24?)
# the rest of these are needed libs or tools
RUN apk add --no-cache postgresql-client bash perl autoconf gnupg ncurses-dev ncurses-libs ncurses-terminfo openssl-dev openssl libressl-dev m4 openssh

# sanity check because lz4 isn't showing up in a later build that depends on this one (wtf?)
# RUN find / -name lz4

# make sure psql is there (sanity check)
RUN psql --version

# make sure an openssl lib is there (sanity check)
RUN find / -iname '*openssl*'

# Install shadow to get usermod (for easier user-edit compatibility with other linux distros)
RUN apk add --no-cache shadow

# do the rest as unprivileged app user
# but first, make sure root's and the app user's shell are zsh too
# RUN find / -name zsh
RUN usermod --shell /bin/zsh root
# and the app directory is owned by this user
RUN chown -R ${APP_USER}:${APP_GROUP} /app
# RUN usermod --shell /bin/zsh -g ${APP_USER} ${APP_GROUP} 
USER ${APP_USER}:${APP_GROUP}
WORKDIR ${HOME}

# install asdf in order to get elixir/erlang/nodejs lined up with .tool-versions
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git $HOME/.asdf
RUN echo -e '\nsource $HOME/.asdf/asdf.sh' >> $HOME/.zshrc
# The asdf installation script fails with "bad substitution" if the standard sh is used to run it in Docker
# Aaaaand it also won't modify PATH properly, so we do it manually
# RUN . $HOME/.asdf/asdf.sh
# RUN chmod +x $HOME/.asdf/asdf.sh
# RUN . $HOME/.asdf/asdf.sh
# RUN source bin/custom_asdf_hook.sh
ENV PATH=$HOME/.asdf/shims:$HOME/.asdf/bin:${PATH}
# RUN echo $PATH

# now install asdf plugins and deps (note: make sure postgres is NOT included here!)
COPY --chown=${APP_USER}:${APP_GROUP} bin/asdf-install-plugins ${HOME}/
# COPY --chown=${APP_USER}:${APP_GROUP} bin/asdf-install-versions ${HOME}/
COPY --chown=${APP_USER}:${APP_GROUP} .tool-versions ${HOME}/
# RUN ls -al

# Now install erlang, elixir, node, etc.
# Need to set up openssl env path so kerl (via asdf) compiles erlang with openssl properly
# --disable-parallel-configure --disable-sctp were added when OTP24 wouldn't build
# May want to sync this up with local dev by passing it in as an env var/build argument
ENV KERL_CONFIGURE_OPTIONS="--disable-parallel-configure --disable-sctp --disable-wx --disable-debug --disable-silent-rules --without-javac --enable-shared-zlib --enable-hipe --enable-smp-support --enable-threads --enable-kernel-poll"
RUN ./asdf-install-plugins
# RUN ./asdf-install-versions
RUN asdf install
# ENV PATH=$HOME/.asdf/installs/*/*/bin:${PATH}
RUN echo $PATH
RUN rm asdf-install-plugins 

# sanity checks
RUN whoami
USER root:root
# RUN find / -name mix
# RUN which mix
# RUN which erl
# RUN ["mix", "--version"]

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
ENV PATH=${HOME}/.cargo/bin:$PATH

# Install Trivy vulnerability scanner
# RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ${HOME}/bin

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

USER root:root

# bind mount will be to /app from cwd
WORKDIR $HOME

RUN chown -R ${APP_USER}:${APP_GROUP} $HOME

COPY --chown=$APP_USER:$APP_GROUP . .

USER $APP_USER:$APP_GROUP

# sanity checks
RUN echo ${PATH}
RUN which mix

ENV MIX_ENV=test

RUN mix local.hex --force && \
  mix hex.organization auth oban --key ${OBAN_LICENSE_KEY} && \
  mix deps.get --force && \
  mix local.rebar --force && \
  mix deps.compile

RUN mix test

##### DEV TARGET #####
FROM build AS dev

USER root:root

# the port we serve from
EXPOSE 4000

RUN chown ${APP_USER}:${APP_USER} /app

# add common dev-only tooling
RUN apk add --no-cache git curl inotify-tools
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

USER ${APP_USER}:${APP_USER}
ENV SHELL=/bin/zsh

WORKDIR /home/${APP_USER}

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

#################################
##### PREPARE RELEASE BUILD #####
#################################
FROM build AS prod_build

USER root:root

# make a temp dir to hold the code
RUN mkdir -p /code
# USER ${APP_USER}:${APP_GROUP}

WORKDIR /
# add github hostkey
# RUN ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
# shallow clone latest commit using https which doesn't require ssh, to temp dir, then copy in, otherwise git complains (non-empty dir)
RUN git clone --depth=1 https://github.com/pmarreck/mpnetwork.git code
# remove git-specific files
RUN rm -rf /code/.git
# copy all the code into app
RUN cp -R code/* /app/
# own app with the app user
RUN chown -R ${APP_USER}:${APP_GROUP} /app
# rw everything for the app user
# RUN chmod -R 660 /app
# rwx all subdirectories
# RUN chmod 770 $(find /app -type d)
# remove code staging area
RUN rm -rf /code

USER ${APP_USER}:${APP_GROUP}
WORKDIR /app
RUN source $HOME/.asdf/asdf.sh
RUN asdf reshim

# troubleshooting
# RUN ls -al

# copy in relevant home directory files (rust, asdf) from the build user
# COPY --from=build ${HOME}/.rustup ${HOME}/.cargo ${HOME}/.asdf .
# own it with the app user
# RUN chown -R ${APP_USER}:${APP_GROUP} /app

# sanity check
# APP_USER root:root
# RUN find / -iname *lz4*
# APP_USER ${APP_USER}:${APP_GROUP}
# RUN fuck
# APP_USER ${APP_USER}:${APP_GROUP}

# set the PATH prepending the rust and asdf necessities that were copied to the app user
# ENV PATH=/app/bin:/app/.asdf/shims:/app/.asdf/bin:/app/.cargo/bin:$PATH

# tell asdf to do its thing
# ENV KERL_CONFIGURE_OPTIONS="--with-ssl=/usr/include/openssl --disable-debug --disable-silent-rules --without-javac --enable-shared-zlib --enable-dynamic-ssl-lib --enable-hipe --enable-sctp --enable-smp-support --enable-threads --enable-kernel-poll"
# RUN ["bash", "asdf-install-plugins"]
# RUN asdf install

# run tests first
# first make sure mix is set up
# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix hex.organization auth oban --key ${OBAN_LICENSE_KEY}
RUN mix do deps.get, deps.compile
RUN mix phx.digest
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN npm run --prefix ./assets deploy
RUN mix do compile, release --overwrite

# ENV MIX_ENV=test
# RUN mix deps.get
# sanity check- print the env
# RUN env

# troubleshooting
# RUN ls -al
# RUN rm -rf _build

# RUN mix test

# run prod build
# ENV MIX_ENV=prod

# run db migrations?
RUN mix ecto.migrate

#####################################
##### PREPARE PRODUCTION TARGET #####
#####################################
FROM alpine:latest AS prod

EXPOSE 80 443

ENV APP_NAME="mpnetwork"
ENV APP_USER="app"
ENV APP_GROUP=${APP_USER}
ENV APP_UID=6969
ENV APP_GID=6969
ENV SHELL="/bin/zsh"
ENV HOME="/${APP_USER}"

ENV MIX_ENV=prod

RUN mkdir -p /app

# add any runtime necessities
# currently disabled since we basically copy all of /usr for now due to all the deps VIPS and elxvips require
# RUN apk add --no-cache openssl ncurses-libs

# Create the app group
RUN addgroup --gid $APP_GID ${APP_GROUP}
# Add the app user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "${HOME}" \
    --ingroup "$APP_GROUP" \
    --no-create-home \
    --uid "$APP_UID" \
    --shell "$SHELL" \
    "$APP_USER"

# Copy system binaries from build that we need to run npm and other things
# Will want to trim this down later, just want something that works for now
COPY --from=build /usr /usr

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
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} $elixir_build_dir/assets/package.json $elixir_build_dir/assets/package-lock.json ./assets/

COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} /app/* ./

# what the hell is it missing? It keeps saying "failed to compute cache key: "/app/_build/prod/rel/mpnetwork" not found: not found"
# and seemingly running the build steps in random order... and then also not running this command!!
RUN find /

COPY --chown=${APP_USER}:${APP_GROUP} /app/_build/prod/rel/${APP_NAME:-APP_NAME_env_missing} ./

# USER ${APP_USER}:${APP_GROUP}
# RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} priv priv
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} assets assets
# RUN npm run --prefix ./assets deploy

# Install hex + rebar
# RUN mix local.hex --force && \
#     mix local.rebar --force

# install mix dependencies
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} mix.exs mix.lock ./
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} config config
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} VERSION VERSION

# Scan for local vulnerabilities with Trivy
# I can't seem to echo or cat the stdout of this command, so commenting out for now
# RUN echo $(trivy fs /)

# compile and build release
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} lib lib
# uncomment COPY if rel/ exists... may not need anyway?
# COPY --from=prod_build --chown=${APP_USER}:${APP_GROUP} rel rel

# RUN mix do compile, release --overwrite

# COPY --chown=${APP_USER}:${APP_GROUP} /app/_build/prod/rel/${APP_NAME:-APP_NAME_env_missing} ./
# COPY --chown=nobody:nobody /app/_build/prod/lib/$APP_NAME ./

# USER root:root

# RUN chown ${APP_USER}:${APP_GROUP} /app

USER ${APP_USER}:${APP_GROUP}

CMD ["bin/$APP_NAME", "start"]

# HEALTHCHECK --interval=1m --timeout=3s \
#   CMD curl -f http://localhost/ || exit 1
