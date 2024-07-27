{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes"; # Enable Flakes.
      flake-registry = ""; # Disable Global Registry.
      nix-path = config.nix.nixPath; # Workaround for broken NIX_PATH [https://github.com/NixOS/nix/issues/9574].
    };
    channel.enable = false; # Disable Channels.
    # Make flake registry and nix path match flake inputs.
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [ "kvm-intel" ]; # Kernel Modules.
    kernel.sysctl = { "vm.swappiness" = 10;}; # Reduce swappiness.
  };

  hardware = {
    # NVidia 1/2.
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    opengl.enable = true;
    pulseaudio.enable = false; # Pipewire 1/3.
  };

  sound = {
    enable = true;
  };

  security = {
    rtkit.enable = true; # Pipewire 2/3.
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    #wireless.enable = true;  # Enable wireless support via wpa_supplicant.
    proxy = {
      #default = "http://user:password@proxy:port/";
      #noProxy = "127.0.0.1,localhost,internal.domain";
    };
  };

  time = {
    timeZone = "America/Sao_Paulo"; # Local time zone.
  };

  # Select internationalisation properties.
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

  services = {
    xserver = {
      enable = true; # Enable X11 windowing system.
      # Configure keymap in X11.
      xkb = {
        layout = "br";
        variant = "";
      };
      # Enable GNOME Desktop Environment.
      displayManager = {
        gdm.enable = true;
      };
      desktopManager = {
        gnome.enable = true;
      };
      videoDrivers = [ "nvidia" ]; # NVidia 2/2.
      # Screen tearing fix.
      screenSection = ''
        Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
        Option "AllowIndirectGLXProtocol" "off"
        Option "TripleBuffer" "on"
      '';
    };
    printing.enable = true; # Enable CUPS to print documents.
    # Pipewire 3/3.
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    flatpak.enable = true; # Flatpak 1/2.
    spice-vdagentd.enable = true; # Virtualisation 1/3.
  };

  systemd = {
    services = {
      # Flatpak 2/2.
      configure-flathub-repo = {
        wantedBy = ["multi-user.target"];
        path = [ pkgs.flatpak ];
        script = ''
          flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
      };
    };
  };

  # Configure console keymap.
  console.keyMap = "br-abnt2";

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
        shell = pkgs.zsh; # ZSH 1/2.
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
      yarn
      zoom-us zsh
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
    # ZSH 2/2.
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
    # Virtualisation 2/3.
    virt-manager = {
      enable = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      #dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };

  # Virtualisation 3/3.
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
    # Development.
    docker.enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
