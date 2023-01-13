{
  description = "The site code for mprealestateboard.network";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      {
        devShells.default = (import ./shell.nix)
            { pkgs = nixpkgs.legacyPackages.${system}; };
      }
    );
}