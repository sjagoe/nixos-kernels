{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      kernelHashes = (builtins.fromJSON (builtins.readFile ./kernels.json)).hashes;

      mainline = import ./mainline;
      mainlinePackages = builtins.listToAttrs
        (map
          (system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            { name = system; value = mainline.generatePackages system kernelHashes pkgs; })
          systems);

      surfaceKernelRelease = "6.18";
      surfaceKernelVersion =
        builtins.elemAt
          (builtins.filter
            (version: (builtins.match "^${lib.escapeRegex surfaceKernelRelease}\.[[:digit:]]+" version) != null)
            (builtins.attrNames kernelHashes))
          0;

      surfacePackages = {
        x86_64-linux = import ./surface-kernel {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          version = surfaceKernelVersion;
          hash = kernelHashes.${surfaceKernelVersion};
        };
      };

      packages = lib.attrsets.recursiveUpdate mainlinePackages surfacePackages;

      runner-size = "8-vcpu";
      runner-arch = arch:
        if (arch == "aarch64-linux") then
          "arm-" else "";
      runner-label = arch:
        "avrea-ubuntu-latest-${runner-arch arch}${runner-size}";

      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      nixos-release = lock.nodes.nixpkgs.original.ref;
    in
      {
        inherit packages;
        ci.build =
          lib.flatten (map
            ({ runs-on, arch, pkgs }:
              map (pkg: { inherit runs-on nixos-release; build = ".#packages.${arch}.${pkg}"; }) (builtins.attrNames pkgs))
            (lib.mapAttrsToList
              (arch: pkgs: { runs-on = runner-label arch; inherit arch pkgs; })
              packages));
      };
}
