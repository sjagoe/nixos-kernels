{
  description = "NixOS Kernels from mainline kernel.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05-small";
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
        nixosModules = rec {
          nixos-kernels = default;
          default = { config, pkgs, lib, ... }:
            let
              inherit (lib) mkIf mkEnableOption mkOption mkPackageOption types;
              blockedModules = [
                # Copy Fail CVE-2026-31431
                "af_alg"
                "algif_hash"
                "algif_skcipher"
                "algif_rng"
                "algif_aead"

                # dirtyfrag CVE-2026-43284 & CVE-2026-43500
                "esp4"
                "esp6"
                "rxrpc"

                # PinTheft
                # https://openwall.com/lists/oss-security/2026/05/19/37
                "rds"
                "rds_rdma"
                "rds_tcp"
              ];
            in
              {
                options.nixos-kernels = {
                  enable = (mkEnableOption "Enable custom kernel builds");
                  package = mkOption {
                    default = self.packages.${pkgs.stdenv.hostPlatform.system}.linux_6_18;
                    type = types.raw;
                  };
                  force = mkOption {
                    type = types.bool;
                    default = false;
                  };
                  blockedModules = mkOption {
                    type = types.listOf types.str;
                    default = blockedModules;
                  };
                };

                config =
                  let
                    cfg = config.nixos-kernels;
                    linuxPackages = pkgs.linuxPackagesFor cfg.package;
                  in
                    mkIf cfg.enable {
                      nixos-kernels.blockedModules = lib.mkDefault blockedModules;

                      boot.kernelPackages = if (cfg.force) then
                        lib.mkForce linuxPackages else linuxPackages;
                      boot.extraModprobeConfig =
                        let
                          blacklists = map (m: "blacklist ${m}") cfg.blockedModules;
                          installs = map (m: "install ${m} /bin/false") cfg.blockedModules;
                        in
                          lib.concatStringsSep "\n" (blacklists ++ installs);
                    };
              };
        };
        inherit packages;
        ci.build =
          let
            pathToHash = path:
            builtins.elemAt
              (builtins.match "^/nix/store/([^-]+).*" path) 0;
            outputPaths = package: map (out: package.${out}.outPath) package.outputs;
            outputHashes = paths: map pathToHash paths;
          in
          lib.flatten (map
            ({ runs-on, arch, pkgs }:
              map (pkg:
                let
                  paths = outputPaths pkgs.${pkg};
                in
                  {
                    inherit runs-on nixos-release;
                    build = ".#packages.${arch}.${pkg}";
                    outputHashes = (outputHashes paths);
                    paths = paths;
                  })
                (builtins.attrNames pkgs))
            (lib.mapAttrsToList
              (arch: pkgs: { runs-on = runner-label arch; inherit arch pkgs; })
              packages));
      };
}
