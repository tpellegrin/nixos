{ inputs, ... }: {
  # Custom packages.
  additions = final: _prev: let
    pkgs = import ../pkgs {
      inherit (final) pkgs;
    };
  in pkgs // {
    gnome-shell-extension-pano = final.callPackage ../pkgs/gnome-shell-extension-pano.nix { };
  };

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  stable = final: _: {
    stable = inputs.nixpkgs-stable.legacyPackages.${final.system};
  };

  unstable-packages = final: prev: {
    unstable = inputs.nixpkgs-unstable.legacyPackages.${final.system};
  };
}
