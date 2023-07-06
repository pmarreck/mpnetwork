{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # 22.11";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      #### SHELL DEFINITION(S) ####
      devShells = forEachSystem
        (system:
          # "legacyPackages" is how nix flakes integrate with pre-flakes Nix
          with nixpkgs.legacyPackages.${system};
          let
            name = "mpnetwork";
            inherit (lib) optional optionals;
            inherit (stdenv) isLinux isDarwin;
            erlang = erlangR26;
            elixir = beam.packages.erlangR26.elixir_1_15;
            postgresql = postgresql_15;
          in
          {
            default = pkgs.mkShell {
              enableParallelBuilding = true;
              # nativeBuildInputs are packages that are only needed at build time, and are not required at runtime
              nativeBuildInputs = [
                pkg-config # for compiling native extensions
                bashInteractive # for interactive bash shell
              ];
              # buildInputs are packages that your project depends on at runtime
              # Since we used "with" above, we can refer to the packages directly
              # instead of namespaced as, for example, "pkgs.erlang" or "pkgs.elixir"
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
                nix-direnv
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
                # mix2nix
                which
                ripgrep
              ] ++ optional isLinux gigalixir # gigalixir CLI is broken on darwin as of 3/2023; need to install some other way impurely!
                ++ optional isLinux inotify-tools
                ++ optional isLinux libnotify
                ++ optional isDarwin terminal-notifier
                ++ optionals isDarwin (with darwin.apple_sdk.frameworks; [
                    CoreFoundation
                    CoreServices
                ]);
              inputsFrom = [ erlang elixir vips ];
              shellHook = ''
                export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1;
                export NIXPKGS_ALLOW_INSECURE=1;
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
              '';
            };
          }
        );
      #### BUILD DEFINITION(S) ####
      packages = forEachSystem
        (system:
          with nixpkgs.legacyPackages.${system};
          let
            name = "mpnetwork";
            erlang = erlangR26;
            elixir = beam.packages.erlangR26.elixir_1_15;
            buildInputs = [
              vips
              elixir
              erlang
              hex
              rebar
              nodejs
              yarn
            ];
          in
          {
            default = stdenv.mkDerivation {
              inherit name;
              src = ./.;
              inherit buildInputs;
              buildPhase = ''
                export LANG=en_US.UTF-8
                echo "Fetching dependencies for ${name}..."
                ${elixir}/bin/mix deps.get
                echo "Compiling assets for ${name}..."
                ${nodejs}/bin/npm install --prefix assets
                ${nodejs}/bin/npm run deploy --prefix assets
                ${elixir}/bin/mix phx.digest
                echo "Building ${name} release..."
                MIX_ENV=prod ${elixir}/bin/mix release
              '';
              installPhase = ''
                mkdir -p $out
                cp -R _build/prod/rel/${name}/* $out/
              '';
            };
          });
    };
}
