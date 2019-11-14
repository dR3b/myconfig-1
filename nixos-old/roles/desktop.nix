# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, lib, pkgs, ... }:
{
  options = {
    myconfig.roles.xmonad = {
      enable = lib.mkEnableOption "Xmonad Desktop environment";
    };
    myconfig.roles.sway = {
      enable = lib.mkEnableOption "Sway desktop environment";
    };
    myconfig.roles.xfce = {
      enable = lib.mkEnableOption "Xfce desktop environment";
    };
    myconfig.roles.vnc = {
      enable = lib.mkEnableOption "VNC desktop environment";
    };
  };

  imports = [
################################################################################
    { # desktop
      config = lib.mkIf (config.myconfig.roles.xmonad.enable ||
                         config.myconfig.roles.sway.enable ||
                         config.myconfig.roles.xfce.enable ||
                         config.myconfig.roles.vnc.enable) {
        environment = {
          systemPackages = with pkgs; [
            arandr
            xlibs.xmodmap xlibs.xset xlibs.setxkbmap
            xclip
          # misc
            xf86_input_wacom
            libnotify # xfce.xfce4notifyd # notify-osd
            vanilla-dmz
          ];
          interactiveShellInit = ''
            alias file-roller='${pkgs.xarchiver}/bin/xarchiver'
          '';
        };

        services.printing = {
          enable = true;
          drivers = [ pkgs.gutenprint pkgs.hplip ];
          # add hp-printer with:
          # $ nix run nixpkgs.hplipWithPlugin -c sudo hp-setup
        };
        
        location.latitude = 48.2;
        location.longitude = 10.8;

        fonts = {
          enableFontDir = true;
          enableGhostscriptFonts = true;
          fonts = with pkgs; [
            dejavu_fonts
            corefonts
            inconsolata
          ];
        };
      };
    }
    { # desktop (x server related)
      config = lib.mkIf (config.myconfig.roles.xmonad.enable ||
                        config.myconfig.roles.xfce.enable ||
                        config.myconfig.roles.vnc.enable) {
        services = {
          xserver = {
            enable = true;
            autorun = true;
            layout = "de";
            xkbVariant = "neo";
            xkbOptions = "altwin:swap_alt_win";
            enableCtrlAltBackspace = true;

            displayManager = {
              slim = {
                enable = true;
                defaultUser = "mhuber";
                # TODO: this is no longer working!
                # theme = "${pkgs.myconfig.slim-theme}/share/my-slim-theme";
                # theme = "${pkgs.myconfig.slim-theme}/share/my-slim-theme.tar.gz";
                # theme = "${pkgs.myconfig.slim-theme}/share/my-slim-theme.zip";
              };
              sessionCommands = ''
                ${pkgs.xlibs.xsetroot}/bin/xsetroot -cursor_name ${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ/cursors/left_ptr 128 &disown
                if test -e $HOME/.Xresources; then
                  ${pkgs.xorg.xrdb}/bin/xrdb -merge $HOME/.Xresources &disown
                fi
                ${pkgs.myconfig.background}/bin/myRandomBackground &disown
                ${pkgs.xss-lock}/bin/xss-lock ${pkgs.myconfig.background}/bin/myScreenLock &disown
              '';
            };
          };

          cron = {
            enable = true;
            systemCronJobs = [
              "*/10 * * * *  mhuber ${pkgs.myconfig.background}/bin/myRandomBackground >> /tmp/cronout 2>&1"
            ];
          };

          redshift = {
            enable = true;
            # temperature.day = 5500;
            # temperature.night = 3500;
          };

        };
      };
    }
################################################################################
    { # xmonad
      config = lib.mkIf (config.myconfig.roles.xmonad.enable) {
        environment.systemPackages = with pkgs; [ dzen2 ];

        # system.activationScripts.cleanupXmonadState = "rm $HOME/.xmonad/xmonad.state || true";

        services.xserver = {
          windowManager = {
            # xmonad = {
            #   enable = true;
            #   enableContribAndExtras = true;
            #   # extraPackages = haskellPackages: [ pkgs.myconfig.xmonad-config ];
            # };
            default = "myXmonad";
            session = [{
              name = "myXmonad";
              start = ''
                exec &> >(tee -a /tmp/myXmonad.log)
                echo -e "\n\n$(date)\n\n"
                ${pkgs.myconfig.my-xmonad}/bin/xmonad &
                waitPID=$!
              '';
            }];
          };

          desktopManager = {
            xterm.enable = false;
            default = "none";
          };
        };
      };
      imports = [{
        environment.systemPackages = with pkgs; [
          rxvt_unicode_with-plugins rxvt_unicode.terminfo
        ];
        services.urxvtd = {
          enable = true;
          # users = [ "mhuber" ];
          # urxvtPackage = pkgs.rxvt_unicode_with-plugins;
        };
      }];
    }
################################################################################
    { # sway
      config = lib.mkIf config.myconfig.roles.sway.enable {
        programs.sway = {
          enable = true;
          extraSessionCommands = ''
          xrdb ~/.Xresources
          export SDL_VIDEODRIVER=wayland
          # needs qt5.qtwayland in systemPackages
          export QT_QPA_PLATFORM=wayland
          export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
          # Fix for some Java AWT applications (e.g. Android Studio),
          # use this if they aren't displayed properly:
          export _JAVA_AWT_WM_NONREPARENTING=1
          '';
        };
        environment.systemPackages = with pkgs; [
          grim # for screenshots
          qt5.qtwayland
        ];
      };
    }
################################################################################
    { # xfce
      config = lib.mkIf config.myconfig.roles.xfce.enable {
        services.xserver.desktopManager.xfce.enable = true;
      };
    }
################################################################################
    { # vnc
      config = lib.mkIf config.myconfig.roles.vnc.enable {
        environment.systemPackages = with pkgs; [
          x11vnc
        ];
        networking.firewall.allowedUDPPorts = [ 5900 ];
        networking.firewall.allowedTCPPorts = [ 5900 ];
      };
    }
  ];
}