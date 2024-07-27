{ config, pkgs, lib, inputs, ... }:

{
  # User specific configuration
  home.username = "thiago";
  home.homeDirectory = "/home/thiago";
  home.stateVersion = "24.05";

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  # User profile packages.
  home.packages = with pkgs; [
    # TODO
  ];

  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
      ];
      userSettings = {
        "terminal.integrated.fontFamily" = "Hack";
      };
    };

    firefox = {
      enable = true;
      profiles.thiago = {
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          darkreader
        ];
      };
    };

    gtk = {
      enable = true;
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
    };
  };
}
