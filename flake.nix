# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    flake-utils.lib.eachDefaultSystem (sys:
      let
        pkgs = import nixpkgs { system = sys; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
            git
            newt
          ];
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    ) // {
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          ({ pkgs, ... }: {
            boot.zfs.forceImportRoot = false;

            environment.systemPackages = with pkgs; [
              just
              disko
              newt
            ];

            environment.etc."nixos-installer-source".source = pkgs.fetchgit {
              url = "https://github.com/georgehulme/nixos-steam-config.git";
              rev = "refs/heads/main";
              leaveDotGit = true;
              sha256 = "sha256-vEBdxZO6pj1TKqTCyx+4lKPgv8Xd47MS3Ph2QgBCSHc=";
            };

            system.activationScripts.copyInstallerScript = ''
              mkdir -p /home/nixos
              cp ${./install-nixos.sh} /home/nixos/install-nixos.sh
              chmod +x /home/nixos/install-nixos.sh
              chown nixos:users /home/nixos/install-nixos.sh
              cp ${./justfile-live} /home/nixos/justfile
              chown nixos:users /home/nixos/justfile
            '';
          })
        ];
      };
    };
}
