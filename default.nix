# run this with: nix-shell --pure --show-trace
let
  unstable = import <nixos-unstable> { }; #(fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) { };
in
{ nixpkgs ? import <nixpkgs> {} }:
with nixpkgs;
let
  elixir = beam.packages.erlangR25.elixir_1_13;
in
mkShell {
  buildInputs = [
    unstable.vips
    pkg-config
    git
    erlangR25
    elixir
    # $%&* locales...
    unstable.glibcLocales
    unstable.glibc
    postgresql_13
  ];

  shellHook = ''
    export APP_NAME="mpnetwork";
    export POSTGRES_PASSWORD="postgres";
    export TEST_DATABASE_URL="ecto://postgres:postgres@localhost:5432/mpnetwork_test";
    export DATABASE_URL="ecto://postgres:postgres@localhost:5432/mpnetwork_dev";
    export STATIC_URL="localhost";
    export ERL_AFLAGS="-kernel\ shell_history\ enabled";
    export SECRET_KEY_BASE="ThisIsATestThisIsATestThisIsATestThisIsATestThisIsATestThisIsATest";
    export SPARKPOST_API_KEY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    export LIVE_VIEW_SIGNING_SALT="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    export KERL_CONFIGURE_OPTIONS="--disable-debug\ --disable-silent-rules\ --without-javac\ --enable-shared-zlib\ --enable-dynamic-ssl-lib\ --enable-hipe\ --enable-sctp\ --enable-smp-support\ --enable-threads\ --enable-kernel-poll\ --enable-wx\ --enable-darwin-64bit";
    export LOGFLARE_API_KEY="XXXXXXXXXXXX";
    export LOGFLARE_DRAIN_ID="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
    export FQDN="localhost";
    export OBAN_LICENSE_KEY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    export LC_ALL="en_US.UTF-8";
    export SSL_CERT_FILE="/etc/pki/tls/certs/ca-bundle.crt";
    export CURL_CA_BUNDLE="$SSL_CERT_FILE"; # this is the value of $SSL_CERT_FILE ; obviously this is brittle and may change
    export GIT_SSL_CAINFO="/etc/ssl/certs/ca-certificates.crt";
    export MIX_HOME=$(pwd)/.mix;
  '';
}
