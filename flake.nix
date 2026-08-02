{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      kernelHashes = (builtins.fromJSON (builtins.readFile ./kernels.json)).hashes;

      mainline = import ./mainline;
      mainlinePackages' =
        mainline.generatePackages "x86_64-linux" kernelHashes nixpkgs.legacyPackages.x86_64-linux;
      mainlinePackages = builtins.listToAttrs
        (map
          (system: { name = system; value = mainline.generatePackages system kernelHashes nixpkgs.legacyPackages.${system}; })
          systems);

      surfaceKernelRelease = "6.18";
      surfaceKernelVersion =
        builtins.elemAt
          (builtins.filter
            (version: (builtins.match "^${nixpkgs.lib.escapeRegex surfaceKernelRelease}\.[[:digit:]]+" version) != null)
            (builtins.attrNames kernelHashes))
          0;

      surfacePackages = {
        x86_64-linux = import ./surface-kernel {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          version = surfaceKernelVersion;
          hash = kernelHashes.${surfaceKernelVersion};
        };
      };
    in
      {
        packages = nixpkgs.lib.attrsets.recursiveUpdate mainlinePackages surfacePackages;
      };
}
