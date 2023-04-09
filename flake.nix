{
  description = "Shipnix server configuration for mpnetwork-staging";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils } @attrs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # system = "x86_64-${builtins.currentSystem}";
        pkgs = nixpkgs.legacyPackages.${system};
        overlay-unstable = final: prev: {
          unstable = nixpkgs-unstable.legacyPackages.${prev.system};
          # use this variant if unfree packages are needed:
          # unstable = import nixpkgs-unstable {
          #  inherit system;
          #  config.allowUnfree = true;
          # };
        };
      in
        {
            # packages = rec {
            #   shipnix = pkgs.callPackage ./nixos/ship.nix { };
            # };
            apps = {
              shipnix = {
                type = "app";
                program = "${self.defaultPackage}/bin/shipnix";
              };
            };
            nixosConfigurations."mpnetwork-staging" = nixpkgs.lib.nixosSystem {
              specialArgs = attrs // {
                environment = "production";
              };
              modules = [
                # Overlays-module makes "pkgs.unstable" available in configuration.nix
                ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
                ./nixos/configuration.nix
              ];
            };
            devShells.default = import ./shell.nix { inherit pkgs system; };
        }
    );
}
