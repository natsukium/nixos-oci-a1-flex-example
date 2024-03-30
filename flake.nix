{
  description = "NixOS on Oracle Cloud Infrastructure A1 flex";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      sshAuthorizedKeys = [
        "ssh-ed25519 your-ssh-public-key"
      ];
    in
    {
      nixosConfigurations = {
        nixos-example = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            disko.nixosModules.disko
            (
              { pkgs, ... }:
              {
                imports = [
                  ./hardware-configuration.nix
                  ./disko-config.nix
                ];

                boot.loader.systemd-boot.enable = true;
                boot.loader.efi.canTouchEfiVariables = true;

                boot.kernelPackages = pkgs.linuxPackages_latest;

                system.stateVersion = "23.11";

                networking = {
                  hostName = "nixos-example";
                };

                services.openssh = {
                  enable = true;
                  settings.PasswordAuthentication = false;
                };

                programs.ssh.startAgent = true;

                nix.settings = {
                  experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                };

                environment.systemPackages = with pkgs; [
                  fastfetch
                  vim
                ];

                users.users.root = {
                  initialPassword = "nixos-example123";
                  openssh.authorizedKeys.keys = sshAuthorizedKeys;
                };

                users.users.nixos-example = {
                  home = "/home/nixos-example";
                  isNormalUser = true;
                  initialPassword = "nixos-example123";
                  extraGroups = [ "wheel" ];
                  openssh.authorizedKeys.keys = sshAuthorizedKeys;
                };
              }
            )
          ];
        };
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              (terraform.withPlugins (p: [
                p.external
                p.null
                p.oci
              ]))
            ];
          };
        }
      );
    };
}
