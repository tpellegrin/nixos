{ 
  config, 
  pkgs, 
  ... 
}: {
  services = {

    # Xserver and Desktop Environment.
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

      videoDrivers = [ "amdgpu" ];
    };

    printing.enable = true; # Enable CUPS to print documents.

    # Audio.
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };

    # Virtualization support.
    spice-vdagentd.enable = true;
  };

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

    # Docker (Development/Containerization)
    docker.enable = true;
  };
}
