# Copyright 2017-2018 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, lib, pkgs, ... }:

{
  options = {
    myconfig.roles.dev = {
      enable = lib.mkEnableOption "Dev role";
    };
    myconfig.roles.imagework = {
      enable = lib.mkEnableOption "Imagework role";
    };
    myconfig.roles.wine = {
     enable = lib.mkEnableOption "Wine role";
    };
    myconfig.roles.tex = {
      enable = lib.mkEnableOption "Tex role";
    };
    myconfig.roles.sundtek = {
      enable = lib.mkEnableOption "Sundtek role";
    };
  };

  imports = [
################################################################################
    { # dev
      config = lib.mkIf config.myconfig.roles.dev.enable {
        environment.systemPackages = with pkgs; [
          meld
          gnumake cmake automake
          cloc
          gitAndTools.gitFull
          gitAndTools.tig
          pass-git-helper

          vscode-with-extensions

          python python3

          stack cabal-install cabal2nix
        ] ++ (with pkgs.haskellPackages; [
          # cabal-install
          ghc hlint pandoc
          hdevtools
        ]);
      };
    }
  ################################################################################
    { # wine
      config = let
          wineCfg = {
            wineBuild = "wineWow";
            gstreamerSupport = false;
          };
        in lib.mkIf config.myconfig.roles.wine.enable {
        environment.systemPackages = with pkgs; [
          (wine.override wineCfg)
          (winetricks.override {wine = wine.override wineCfg;})
        ];
        hardware.opengl.driSupport32Bit = true;
      };
    }
################################################################################
    { # tex
      config = lib.mkIf config.myconfig.roles.tex.enable {
        environment.systemPackages = with pkgs; [
          (pkgs.texLiveAggregationFun {
            paths = [
              pkgs.texLive pkgs.texLiveExtra
              pkgs.texLiveBeamer
              pkgs.texLiveCMSuper
            ];
          })
        ];
      };
    }
################################################################################
    { # sundtek
      config = lib.mkIf config.myconfig.roles.sundtek.enable {
        environment.systemPackages = with pkgs; [
          sundtek
        ];
      };
    }
  ];
}