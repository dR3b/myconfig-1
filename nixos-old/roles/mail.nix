# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, lib, pkgs, ... }:

{
  options = {
    myconfig.roles.mail = {
      enable = lib.mkEnableOption "Mail role";
    };
  };

  config = lib.mkIf config.myconfig.roles.mail.enable {
    environment.systemPackages = with pkgs; [
      neomutt
      offlineimap msmtp gnupg abook urlview notmuch
      sxiv
      procmail
      unstable.astroid
      mu isync
      gnome3.gnome-keyring # necessary for mu4e?
    ];

    services.offlineimap = {
      enable = false;
      path = with pkgs; [ notmuch ];
    };
  };
}