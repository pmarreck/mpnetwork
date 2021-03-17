FROM alpine:latest AS build

# syntax=docker/dockerfile:latest

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
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly
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

# Set build ENV
ENV MIX_ENV=prod

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

ARG SECRET_KEY_BASE
ARG LIVE_VIEW_SIGNING_SALT
ARG SPARKPOST_API_KEY
ARG FQDN
ARG STATIC_URL
ARG LOGFLARE_API_KEY
ARG LOGFLARE_DRAIN_ID
ARG DATABASE_URL
ARG OBAN_WEB_LICENSE_KEY
RUN mix hex.organization auth oban --key "$OBAN_WEB_LICENSE_KEY"
RUN mix do deps.get, deps.compile
RUN mix phx.digest

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists... may not need anyway?
COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:latest AS app
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build /usr/local /usr/local

COPY --from=build /usr/include /usr/include

ENV APP_NAME="mpnetwork"

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/$APP_NAME ./

ENV HOME=/app

CMD ["bin/$APP_NAME", "start"]

HEALTHCHECK --interval=1m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
