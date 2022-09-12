self: super:
let
    old_pkgs = import (builtins.fetchTarball {
      name = "release-18.09";
      # Commit hash for release-18.09
      url = "https://github.com/nixos/nixpkgs/archive/925ff360bc33876fdb6ff967470e34ff375ce65e.tar.gz";
      # Hash obtained using `nix-prefetch-url --unpack <url>`
      sha256 = "1qbmp6x01ika4kdc7bhqawasnpmhyl857ldz25nmq9fsmqm1vl2s";
    }) {};
in {
    glibc = old_pkgs.glibc;
    glibcLocales = old_pkgs.glibcLocales;
    glibcIconv = old_pkgs.glibcIconv;
}