# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, pkgs, ... }:

{
  imports = [
    ./hardware/x1extremeG2.nix
    ./hardware/efi.nix
    ./hardware/exfat.nix
    ./hardware/steamcontroller.nix
    ./hardware/pulseaudio.nix
  ];

  myconfig.active-roles = [
    "xmonad" "xfce" # "vnc"
    "mail"
    "work" "virtualization-docker" "dev"
    "imagework"
    "games" # "wine"
    "iot"
  ];

  # swapDevices = [ {
  #   device = "/swapfile";
  #   size = 20480;
  # }];

  boot.initrd.supportedFilesystems = [ "luks" ];
  boot.initrd.luks.devices = [{
    device = "/dev/disk/by-uuid/0b3b85df-65ef-4b2b-8073-a62c5a7346dc";
    name = "crypted";
    preLVM = true;
    allowDiscards = true;
  }];

  services.xserver.displayManager.slim.autoLogin = true;
}
