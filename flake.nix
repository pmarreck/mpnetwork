{
  # stolen and modified from https://github.com/akirak/flake-templates/blob/master/elixir-phoenix/flake.nix
  description = "MPNetwork";

  inputs.pre-commit-hooks = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
  }:
    flake-utils.lib.eachSystem [
      # TODO: Configure your supported architecture(s) here.
      "x86_64-linux"
      "aarch64-linux"
      # "i686-linux"
      "x86_64-darwin"
    ]
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        # Set the Erlang & Elixir versions
        erlangVersion = "erlangR25";
        elixirVersion = "elixir_1_14";
        erlang = pkgs.beam.interpreters.${erlangVersion};
        elixir = pkgs.beam.packages.${erlangVersion}.${elixirVersion};
        elixir_ls = pkgs.beam.packages.${erlangVersion}.elixir_ls;
        nodejs = nodejs-16_x;
        postgresql = postgresql_13;

        inherit (pkgs.lib) optional optionals;
        inherit (stdenv) isLinux isDarwin;

        fileWatchers = with pkgs; (
            optional isLinux inotify-tools
            ++ optional isLinux libnotify
            ++ optional isDarwin terminal-notifier
            ++ optionals isDarwin (with darwin.apple_sdk.frameworks; [
                CoreFoundation
                CoreServices
            ]));
      in rec {
        # TODO: Add your Elixir package
        # packages = flake-utils.lib.flattenTree {
        # } ;

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              nix-linter.enable = true;
              # TODO: Add a linter for Elixir
            };
          };
        };
        devShells.default = nixpkgs.legacyPackages.${system}.mkShell rec {
          buildInputs =
            [
              vips
              pkg-config
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
              yarn
              erlang
              elixir
              elixir_ls
              postgresql
              gigalixir
              mix2nix
            ]
            # ++ (with pkgs; [
            #   nodejs
            # ])
            ++ fileWatchers;

          inherit (self.checks.${system}.pre-commit-check) shellHook;

          LANG = "en-US.UTF-8";
          ERL_AFLAGS = "-kernel shell_history enabled";
          # TODO: Can these just be defined right here instead, and end up in the env?
          # shellHook = ''
          #   export APP_NAME="mpnetwork";
          #   export POSTGRES_PASSWORD="postgres";
          #   export TEST_DATABASE_URL="ecto://postgres:postgres@localhost:5432/mpnetwork_test";
          #   export DATABASE_URL="ecto://postgres:postgres@localhost:5432/mpnetwork_dev";
          #   export STATIC_URL="localhost";
          #   export ERL_AFLAGS="-kernel shell_history enabled";
          #   export SECRET_KEY_BASE="ThisIsATestThisIsATestThisIsATestThisIsATestThisIsATestThisIsATest";
          #   export SPARKPOST_API_KEY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
          #   export LIVE_VIEW_SIGNING_SALT="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
          #   export KERL_CONFIGURE_OPTIONS="--disable-debug\ --disable-silent-rules\ --without-javac\ --enable-shared-zlib\ --enable-dynamic-ssl-lib\ --enable-hipe\ --enable-sctp\ --enable-smp-support\ --enable-threads\ --enable-kernel-poll\ --enable-wx\ --enable-darwin-64bit";
          #   export LOGFLARE_API_KEY="XXXXXXXXXXXX";
          #   export LOGFLARE_DRAIN_ID="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
          #   export FQDN="localhost";
          #   export OBAN_LICENSE_KEY="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
          #   export LANG="en_US.UTF-8";
          #   export SSL_CERT_FILE="/etc/pki/tls/certs/ca-bundle.crt";
          #   export CURL_CA_BUNDLE="$SSL_CERT_FILE"; # this is the value of $SSL_CERT_FILE ; obviously this is brittle and may change
          #   export GIT_SSL_CAINFO="/etc/ssl/certs/ca-certificates.crt";
          #   export MIX_HOME=$PWD/.mix;
          #   export HEX_HOME=$PWD/.hex;
          #   export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH;
          #   export PGDATA=$PWD/.pgdata;
          #   export PGHOST=$PGDATA;
          #   alias dbgo="pg_ctl -l \"$PGDATA/server.log\" -o \"-k $PGHOST\" start";
          #   alias dbno="pg_ctl -o \"-k $PGHOST\" stop"
          #   echo "dbgo starts the database, dbno stops it!"
          # '';
        };
      }
    );
}
