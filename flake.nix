{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      kernelHashes = builtins.fromJSON (builtins.readFile ./kernels.json);
      mainline = import ./mainline;

      mainlinePackages' =
        mainline.generatePackages "x86_64-linux" kernelHashes nixpkgs.legacyPackages.x86_64-linux;
      mainlinePackages = builtins.listToAttrs
        (map
          (system: { name = system; value = mainline.generatePackages system kernelHashes nixpkgs.legacyPackages.${system}; })
          systems);
    in
      {
        packages = mainlinePackages;
      };
}
