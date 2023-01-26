# Shipnix recommended settings
# IMPORTANT: These settings are here for ship-nix to function properly on your server
# Modify with care

{ config, pkgs, ... }:
{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';
    settings = {
      trusted-users = [ "root" "ship" "nix-ssh" ];
    };
  };

  programs.git.enable = true;
  programs.git.config = {
    advice.detachedHead = false;
  };

  services.openssh = {
    enable = true;
    # ship-nix uses SSH keys to gain access to the server
    # Manage permitted public keys in the `authorized_keys` file
    passwordAuthentication = false;
    #  permitRootLogin = "no";
  };


  users.users.ship = {
    isNormalUser = true;
    extraGroups = [ "wheel" "nginx" ];
    # If you don't want public keys to live in the repo, you can remove the line below
    # ~/.ssh will be used instead and will not be checked into version control. 
    # Note that this requires you to manage SSH keys manually via SSH,
    # and your will need to manage authorized keys for root and ship user separately
    openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6uTwqPzazZcZlTnf5SMbS44dmZttgKFT7aUGoncW+b+iWW/bEawMIzWm+V2ELdLzb5+ayCgpTWGVlsE51JhveHPPhPRfw9E8WEJ+KNOwyn5gbLCGbj01qfYYI7zwNuTiKOh+hIO99LmZ9hAfZ6s+6P2mEPt6Wk+7vXuq7KP64xUnAQwDgaEKBeX7c34eiB5D9ujsbZRLmSjYe2JaQ3xOBP5efYNo+kpADW1SL6m5PwFjMSrgepfqYlXWBoMXLUQfR+hNbwURauHXexeGMsf/M7zQREkNJIwZ2z3Mo2b2u41qTmHzy/WmGoBgw458XvPfqcRXw9lj3EXlnpZ8heb2Om58tJl40M4qnnOuxmnTwnbTBbpVmwRtk8WAZmtS1VDh9kzBDeFqIlFlW04Njbj6KivgVp5gVcRXevl0HupYvS9AGNc1DtYUpKnLKv3zFGO//CpSsiA77dJo1hGClQzTMXBo/kv/0jFJ3FYdPKDHl3SK3I4y7uNISv7q1upskfms= ship@tite-ship
"
    ];
  };

  # Can be removed if you want authorized keys to only live on server, not in repository
  # Se note above for users.users.ship.openssh.authorizedKeys.keyFiles
  users.users.root.openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6uTwqPzazZcZlTnf5SMbS44dmZttgKFT7aUGoncW+b+iWW/bEawMIzWm+V2ELdLzb5+ayCgpTWGVlsE51JhveHPPhPRfw9E8WEJ+KNOwyn5gbLCGbj01qfYYI7zwNuTiKOh+hIO99LmZ9hAfZ6s+6P2mEPt6Wk+7vXuq7KP64xUnAQwDgaEKBeX7c34eiB5D9ujsbZRLmSjYe2JaQ3xOBP5efYNo+kpADW1SL6m5PwFjMSrgepfqYlXWBoMXLUQfR+hNbwURauHXexeGMsf/M7zQREkNJIwZ2z3Mo2b2u41qTmHzy/WmGoBgw458XvPfqcRXw9lj3EXlnpZ8heb2Om58tJl40M4qnnOuxmnTwnbTBbpVmwRtk8WAZmtS1VDh9kzBDeFqIlFlW04Njbj6KivgVp5gVcRXevl0HupYvS9AGNc1DtYUpKnLKv3zFGO//CpSsiA77dJo1hGClQzTMXBo/kv/0jFJ3FYdPKDHl3SK3I4y7uNISv7q1upskfms= ship@tite-ship
"
  ];

  security.sudo.extraRules = [
    {
      users = [ "ship" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];
}
