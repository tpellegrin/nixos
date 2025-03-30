{ 
  config,
  lib,
  pkgs, 
  ... 
}: {
  config = lib.optionalAttrs (lib.versionAtLeast lib.trivial.release "24.11") {

    programs = {
      steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        package = pkgs.steam-small.override {
          extraEnv = {
            MANGOHUD = true;
            OBS_VKCAPTURE = true;
            RADV_TEX_ANISO = 16;
            DXVK_HUD = "compiler";
            PULSE_SINK = "game_sink"; # For separate capture
          };
          extraLibraries = p: with p; [
            atk
            dbus
            udev
          ];
        };
        protontricks.enable = true;
      };

      gamemode = {
        enable = true;
      };
    };

    environment.systemPackages = let
      general = with pkgs; [
        discord
        goverlay
        libstrangle
        mangohud
        piper
        vulkan-tools
        wineWowPackages.staging
        steamtinkerlaunch
      ];

      amdgpu = with pkgs; [
        lact
        radeontop
        umr
      ];

      obs = pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          obs-vkcapture
          obs-gstreamer
          wlrobs
        ];
      };
    in
    general ++ amdgpu ++ [ obs ];

    nixpkgs.config = {
      allowUnfree = true;
      allowedUnfreePackages = [
        "steam"
        "steam-original"
        "steam-run"
        "discord"
      ];
    };

    boot = {
      kernel = {
        sysctl = {
          "vm.max_map_count" = 2147483642;
          "kernel.split_lock_mitigate" = 0;
        };
      };
      initrd.kernelModules = [ "amdgpu" ];
    };

    services = {
      xserver.deviceSection = ''
        Option "VariableRefresh" "True"
      '';
      ratbagd.enable = true;
    };

    hardware.steam-hardware.enable = true;

    # SteamTinkerLaunch setup service definition - Handles initial setup and fixes a broken symlink by
    # ensuring the SteamTinkerLaunch directory is correctly created and the symlink points to the right executable.
    systemd.services.steamTinkerLaunchSetup = {
      description = "Setup SteamTinkerLaunch Compatibility Tool";
      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash -c '\

          # Check if the SteamTinkerLaunch directory exists within the compatibility tools path.
          # If the directory does not exist, proceed with running steamtinkerlaunch compat add
          if [ ! -d \"$STEAM_EXTRA_COMPAT_TOOLS_PATHS/SteamTinkerLaunch\" ]; then \
            
            # Run the command to create the folder and setup the tool in Steam.
            /run/current-system/sw/bin/steamtinkerlaunch compat add; \
            
            # Ensure that the symlink points to the correct steamtinkerlaunch executable
            ln -sfn /run/current-system/sw/bin/steamtinkerlaunch \"$STEAM_EXTRA_COMPAT_TOOLS_PATHS/SteamTinkerLaunch/steamtinkerlaunch\"; \
          fi; \
        '";
        Type = "oneshot";
        RemainAfterExit = false;
        Environment = "STEAM_EXTRA_COMPAT_TOOLS_PATHS=/home/thiago/.local/share/Steam/compatibilitytools.d/";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
