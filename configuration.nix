{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes"; # Enable Flakes.
      flake-registry = ""; # Disable Global Registry.
      nix-path = config.nix.nixPath; # Workaround for broken NIX_PATH [https://github.com/NixOS/nix/issues/9574].
      sandbox = "relaxed";
    };
  
    channel.enable = false; # Disable Channels.

    # Make flake registry and nix path match flake inputs.
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [ "kvm-intel" ]; # Kernel Modules.
    kernel.sysctl = { "vm.swappiness" = 10;}; # Reduce swappiness.
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ vulkan-tools ];
    };

    pulseaudio.enable = false; # Handled by Pipewire in services.nix.
  };

  security = {  
    rtkit.enable = true; # Pipewire-related.
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time = {
    timeZone = "America/Sao_Paulo"; # Local time zone.
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  users = {
    users = {
      thiago = {
        description = "Thiago Pellegrin";
        isNormalUser = true;
        extraGroups = [ 
          "corectrl"
          "docker"
          "networkmanager"
          "libvirtd"
          "qemu-libvirtd"
          "kvm"
          "wheel"
        ];
        shell = pkgs.zsh; # ZSH configuration.
      };
    };
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.stable
    ];

    config = {
      allowUnfree = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      albert awscli2
      cherrytree
      discord docker docker-compose
      firefox flyway
      git gnote google-chrome
      jq jetbrains.webstorm
      nodejs_20 nodePackages.pnpm
      oh-my-zsh
      protobuf
      qemu qemu_kvm
      slack spice spice-gtk spice-protocol
      thunderbird teams-for-linux
      virt-manager virt-viewer vscodium
      win-virtio win-spice
      yarn yarn2nix
      zoom-us zsh
      xorg.xvfb xvfb-run
    ] ++ (with gnomeExtensions; [
      alphabetical-app-grid appindicator
      blur-my-shell burn-my-windows
      caffeine
      dash-to-dock
      firefox-pip-always-on-top
      just-perfection
      nothing-to-say
      pano
      tray-icons-reloaded
      vitals
    ]);
  };

  programs = {
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff"; 
      };
    };

    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch";
        cls = "clear";
        code = "${pkgs.vscodium}/bin/codium";
      };
      enableCompletion = true;
      autosuggestions.enable = true;
      promptInit = "";
      ohMyZsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };

    virt-manager = {
      enable = true;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
