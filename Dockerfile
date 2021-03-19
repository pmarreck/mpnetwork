# syntax=docker/dockerfile:latest

FROM alpine:latest AS build

# Set app name
ENV APP_NAME="mpnetwork"

# Set build ENV
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

# first configure locale, which is a mess and defaults to latin1, which is just... NO
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
 && apk add --update --no-cache alpine-sdk \
 && apk add \
    git curl build-base clang zlib libxml2 glib gobject-introspection \
    libjpeg-turbo libexif lcms2 fftw giflib libpng \
    libwebp orc tiff poppler-glib librsvg libgsf openexr \
    libheif libimagequant pango \
 && apk add --update --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community --repository http://dl-3.alpinelinux.org/alpine/edge/main vips-dev

# Install Rust
# RUN apk add --no-cache rust cargo
# Use rustup and default to nightly for now
# RUN curl -sSf sh.rustup.rs | sh -s -- -y --default-toolchain nightly
# RUN (curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly) && source $HOME/.cargo/env && rustup default nightly
# ENV PATH="$HOME/.cargo/bin:$PATH"

# Add Rust and configure
# So apparently dynamically-linked crates won't compile correctly on musl toolchains (as in alpine)
# so we will force static compilation
ENV RUSTFLAGS="-C target-feature=-crt-static"
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --default-toolchain nightly
ENV PATH=/root/.cargo/bin:$PATH

# Install Elixir, Erlang and npm
RUN apk add --no-cache elixir npm

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

# Prepare build dir
WORKDIR /app

# Install Trivy vulnerability scanner
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

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

# assuming these are all already in your ENV of your project directory, perhaps via direnv and an .envrc file...
# docker build --rm --build-arg SECRET_KEY_BASE --build-arg LIVE_VIEW_SIGNING_SALT --build-arg SPARKPOST_API_KEY --build-arg FQDN --build-arg STATIC_URL --build-arg LOGFLARE_API_KEY --build-arg LOGFLARE_DRAIN_ID --build-arg DATABASE_URL --build-arg TEST_DATABASE_URL --build-arg OBAN_WEB_LICENSE_KEY .
ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ARG LIVE_VIEW_SIGNING_SALT
ENV LIVE_VIEW_SIGNING_SALT=${LIVE_VIEW_SIGNING_SALT}
ARG SPARKPOST_API_KEY
ENV SPARKPOST_API_KEY=${SPARKPOST_API_KEY}
ARG FQDN
ENV FQDN=${FQDN}
ARG STATIC_URL
ENV STATIC_URL=${STATIC_URL}
ARG LOGFLARE_API_KEY
ENV LOGFLARE_API_KEY=${LOGFLARE_API_KEY}
ARG LOGFLARE_DRAIN_ID
ENV LOGFLARE_DRAIN_ID=${LOGFLARE_DRAIN_ID}
ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL}
ARG TEST_DATABASE_URL
ENV TEST_DATABASE_URL=${TEST_DATABASE_URL}
ARG OBAN_WEB_LICENSE_KEY
ENV OBAN_WEB_LICENSE_KEY=${OBAN_WEB_LICENSE_KEY}
RUN mix hex.organization auth oban --key "$OBAN_WEB_LICENSE_KEY"
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
RUN mix do compile, release

# test target
FROM build AS test

COPY . .

WORKDIR /app

CMD ["mix", "test"]

# dev target
FROM build AS dev

RUN apk add zsh

COPY . .

WORKDIR /app

CMD ["zsh"]

# prepare release image
FROM alpine:latest AS app
RUN apk add --no-cache openssl ncurses-libs

ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build /usr /usr

# COPY --from=build /usr/local /usr/local

# COPY --from=build /usr/bin /usr/bin

# COPY --from=build /usr/lib /usr/lib

# COPY --from=build /usr/include /usr/include

# COPY --from=build /usr/share /usr/share

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/$APP_NAME ./

ENV HOME=/app

CMD ["bin/$APP_NAME", "start"]

HEALTHCHECK --interval=1m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
