<<<<<<< HEAD
# run this with: nix-shell --pure --show-trace
# let
#   unstable = import (fetchTarball {
#     url = https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz;
#     sha256 = "150xy795rzzy09xidkyrysga6khv5d4ikfz98s2n77a38d7njdwj";
#   }) {
#     inherit system;
#   };
# in
||||||| parent of 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
# run this with: nix-shell --pure --show-trace
let
  unstable = import <nixos-unstable> { }; #(fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) { };
in
=======
## run this with: nix-shell --pure --show-trace
## or via flakes: nix develop
## note: on darwin there's a few things to know.
## Currently only x86_64 builds on darwin are supported
## due to an issue with glibc (GNU) absolutely outright refusing to be compatible with Apple.
## I saw signs that it may be possible to remove glibc as a dependency, but I'm not there yet.
## You may need to fire up a "curated" shell like so, for the flakes approach:
## NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix develop --system x86_64-darwin --impure
## or like so for the traditional Nix (sans Flakes) approach:
## NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-shell --system x86_64-darwin --impure
let
  unstable = import (
    builtins.fetchTarball {
      url = "https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz";
      sha256 = "0jw0wyv3pvzi0pd80zv6y00rvmvisjlns0n70vl0a7m3l9qz24ss"; 
    });
in
>>>>>>> 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
# { pkgs ? import <nixpkgs> { overlays = [(import ./glibc-overlay.nix)]; } }:
<<<<<<< HEAD
{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> { inherit system; } }:
||||||| parent of 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
{ pkgs ? import <nixpkgs> { } }:
=======
{ 
  pkgs ? unstable { inherit system; },
  system ? (if pkgs.stdenv.isDarwin then "darwin" else "linux"),
  # pkgs_aarch64 ? import <nixpkgs> { localSystem = "aarch64-darwin"; },
  # pkgs_x86_64 ? import <nixpkgs> { localSystem = "x86_64-darwin"; },
}:
>>>>>>> 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
with pkgs;
let
  inherit (lib) optional optionals;
  inherit (stdenv) isLinux isDarwin;
<<<<<<< HEAD
  unstable = import (fetchTarball {
    url = https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz;
    sha256 = "0vczd1pgsgnknn814y6bx9vdzhrs78x0m80rzihjv19wz596sril";
  }) {
    inherit system;
  };
  erlang = unstable.erlang; # I like to live dangerously. For fallback, use stable of: # erlangR25;
||||||| parent of 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
  # like a .tool-versions for Nix...
  erlang = erlangR25;
=======
  erlang = erlangR25;
>>>>>>> 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
  elixir = beam.packages.erlangR25.elixir_1_14;
  nodejs = nodejs-16_x;
  postgresql = postgresql_13;
<<<<<<< HEAD
  # inherit (callPackage (fetchGit {
  #   url = https://gitlab.com/transumption/mix-to-nix;
  #   rev = "b70cb8f7fca80d0c5f7539dbfec497535e07d75c";
  # }) {}) mixToNix;
||||||| parent of 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
    inherit (callPackage (fetchGit {
    url = https://gitlab.com/transumption/mix-to-nix;
    rev = "b70cb8f7fca80d0c5f7539dbfec497535e07d75c";
  }) {}) mixToNix;
=======
  ### as of 3/2023, mix2nix breaks on erlang 25 and hasn't been updated in 4 years
  ### I wasn't really using it yet, anyway, but it's a nice idea
  # inherit (callPackage (fetchGit {
  #   url = https://gitlab.com/transumption/mix-to-nix;
  #   rev = "b70cb8f7fca80d0c5f7539dbfec497535e07d75c";
  # }) {}) mixToNix;
>>>>>>> 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
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
    direnv
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
<<<<<<< HEAD
||||||| parent of 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
    gigalixir
    mix2nix
=======
    # mix2nix
>>>>>>> 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
    which
    ripgrep
<<<<<<< HEAD
  ] ++ optional isLinux gigalixir # it is currently broken on darwin as of 3/10/2023 =(
    ++ optional isLinux inotify-tools
||||||| parent of 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
  ] ++ optional isLinux inotify-tools
=======
  ] ++ optional isLinux gigalixir # gigalixir CLI is broken on darwin as of 3/2023; need to install some other way impurely!
    ++ optional isLinux inotify-tools
>>>>>>> 589b887 (Update dependencies in flake.lock and shell.nix, including erlang, elixir, nodejs, and postgresql. Also add gigalixir to shell.nix and remove mix2nix due to compatibility issues with erlang 25. Update system definition in shell.nix to support darwin on x86_64 architecture.)
    ++ optional isLinux libnotify
    ++ optional isDarwin terminal-notifier
    ++ optionals isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
    ]);

  inputsFrom = [ erlang elixir vips ];

  shellHook = ''
    export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1;
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
