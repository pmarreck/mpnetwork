# run this with: nix-shell --pure --show-trace
let
  unstable = import <nixos-unstable> { }; #(fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) { };
in
# { pkgs ? import <nixpkgs> { overlays = [(import ./glibc-overlay.nix)]; } }:
{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  inherit (lib) optional optionals;
  inherit (stdenv) isLinux isDarwin;
  # like a .tool-versions for Nix...
  erlang = erlangR25;
  elixir = beam.packages.erlangR25.elixir_1_14;
  nodejs = nodejs-19_x;
  postgresql = postgresql_13;
    inherit (callPackage (fetchGit {
    url = https://gitlab.com/transumption/mix-to-nix;
    rev = "b70cb8f7fca80d0c5f7539dbfec497535e07d75c";
  }) {}) mixToNix;
in
mkShell {

  # src = ./.;
  
  name = "mpnetwork";

  enableParallelBuilding = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    # busybox
    vips
    gnumake
    gcc
    readline
    openssl
    zlib
    curl
    wget
    libiconv
    # $%&* locales...
    glibcLocales
    glibc
    git
    nodejs
    nodePackages.mocha
    yarn
    erlang
    elixir
    postgresql
    gigalixir
    mix2nix
    which
    ripgrep
  ] ++ optional isLinux inotify-tools
    ++ optional isLinux libnotify
    ++ optional isDarwin terminal-notifier
    ++ optionals isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
    ]);

  inputsFrom = [ erlang elixir vips ];

  shellHook = ''
    export APP_NAME="mpnetwork";
    export POSTGRES_PASSWORD="postgres";
    export TEST_DATABASE_URL="ecto://postgres:postgres@localhost:5432/mpnetwork_test";
    export DATABASE_URL="ecto://postgres:postgres@localhost:5432/mpnetwork_dev";
    export STATIC_URL="localhost";
    export ERL_AFLAGS="-kernel shell_history enabled";
    export SECRET_KEY_BASE="ThisIsATestThisIsATestThisIsATestThisIsATestThisIsATestThisIsATest";
    export SPARKPOST_API_KEY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    export LIVE_VIEW_SIGNING_SALT="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    export KERL_CONFIGURE_OPTIONS="--disable-debug\ --disable-silent-rules\ --without-javac\ --enable-shared-zlib\ --enable-dynamic-ssl-lib\ --enable-hipe\ --enable-sctp\ --enable-smp-support\ --enable-threads\ --enable-kernel-poll\ --enable-wx\ --enable-darwin-64bit";
    export LOGFLARE_API_KEY="XXXXXXXXXXXX";
    export LOGFLARE_DRAIN_ID="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
    export FQDN="localhost";
    export OBAN_LICENSE_KEY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    export LANG="en_US.UTF-8";
    export SSL_CERT_FILE="/etc/pki/tls/certs/ca-bundle.crt";
    export CURL_CA_BUNDLE="$SSL_CERT_FILE"; # this is the value of $SSL_CERT_FILE ; obviously this is brittle and may change
    export GIT_SSL_CAINFO="/etc/ssl/certs/ca-certificates.crt";
    export MIX_HOME=$PWD/.mix;
    export HEX_HOME=$PWD/.hex;
    export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PWD/bin:$PATH;
    export PGDATA=$PWD/.pgdata;
    export PGHOST=$PGDATA;
    alias dbgo="pg_ctl -l \"$PGDATA/server.log\" -o \"-k $PGHOST\" start";
    alias dbno="pg_ctl -o \"-k $PGHOST\" stop -m smart"
    dbstat() { 
      local pgs pgec pgv pgpid pgver; 
      pgs=$(pg_ctl status); 
      pgec=$?; 
      pgpid=$(echo "$pgs" | head -n1 | sed -E 's/^[^0-9]+([0-9]+).+$/\1/');
      pgver=$(echo "$pgs" | tail -n1);
      pgv=$(echo "$pgver" | sed -E 's/^[^-]+-postgresql-([^\/]+).+$/\1/');
      case $pgec in
        0) echo "Postgres version '$pgv' is running (PID: $pgpid)";;
        3) echo "Postgres is not running";;
        4) echo "Postgres cannot run without a proper data directory which is currently defined in PGDATA as: '$PGDATA'";;
        *) echo -e "Postgres status unknown:\n$pgs";;
      esac
      return $pgec;
    }
    echo "dbgo starts the database, dbno stops it, dbstat gives status!"
  '';
}
