{
  description = "Shipnix server configuration for mpnetwork-staging";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
  };

  outputs = { self, nixpkgs, nixpkgs-unstable } @attrs:
    let
      system = "x86_64-linux";
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
      nixosConfigurations."mpnetwork-staging" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = attrs // {
          environment = "production";
        };
        modules = [
          # Overlays-module makes "pkgs.unstable" available in configuration.nix
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
          ./nixos/configuration.nix
        ];
      };
      devShells.default = (import ./shell.nix)
        { pkgs = nixpkgs.legacyPackages.${system}; };
    };
}
    