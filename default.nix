# Copyright 2018 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
funs: pkgs: let
  callPackage = funs.lib.callPackageWith pkgs;

  background = callPackage ./background {
    inherit pkgs;
  };
  slim-theme = callPackage ./background/slim-theme {
    inherit background pkgs;
  };
  scripts = callPackage ./scripts {
    inherit background pkgs;
  };
  my-xmonad = funs.haskellPackages.callPackage ./xmonad {
    inherit scripts pkgs;
  };

  photo-scripts = callPackage ./photo-scripts {
    inherit pkgs;
  };

  # # based on: https://gist.github.com/LnL7/570349866bb69467d0caf5cb175faa74
  # userPackages = pkgs.userPackages or {} // {
  #   ############################################################################
  #   # Default packages:
  #   cacert = funs.cacert;
  #   nix = funs.nix; # don't enable this on multi-user.

  #   ############################################################################
  #   # script to update
  #   nix-rebuild = pkgs.writeScriptBin "nix-rebuild" ''
  #     #!${pkgs.stdenv.shell}
  #     if ! command -v nix-env &>/dev/null; then
  #       echo "warning: nix-env was not found in PATH, add nix to userPackages" >&2
  #       PATH=${funs.nix}/bin:$PATH
  #     fi
  #     exec nix-env -f '<nixpkgs>' -r -iA userPackages "$@"
  #   '';

  #   ############################################################################
  #   # Custom packages:
  # };
in {
  myconfig = {
    nixos-config = import ./nixos;
    inherit
      scripts
      my-xmonad
      background
      slim-theme;
    myconfig-all = funs.buildEnv {
      name = "myconfig-all";
      paths = [scripts my-xmonad background slim-theme];
      pathsToLink = [ "/share" "/bin" ];
    };
  };
  inherit photo-scripts;
}
