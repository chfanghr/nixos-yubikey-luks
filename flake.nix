{
  description = "Set up a LUKS-encrypted filesystem for Yubikey in NixOS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    pre-commit-hooks,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        pre-commit-hooks.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        self',
        pkgs,
        system,
        ...
      }: {
        pre-commit = {
          check.enable = true;
          settings.hooks.alejandra.enable = true;
        };

        packages = {
          pbkdf2Sha512 = pkgs.callPackage ./pbkdf2-sha512 {};
          rbtohex = pkgs.writeShellScriptBin "rbtohex" ''
            od -An -vtx1 | tr -d ' \n'
          '';
          hextorb = pkgs.writeShellScriptBin "hextorb" ''
            tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI'| xargs printf
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = let
            nixpkgsLib = pkgs.lib;
            listUtils = nixpkgsLib.lists;
            stringUtils = nixpkgsLib.strings;
            commonPackages = with pkgs;
            with self'.packages; [
              treefmt
              alejandra
              openssl
              pbkdf2Sha512
              yubikey-personalization
              rbtohex
              hextorb
            ];
            linuxPackages =
              listUtils.optional
              (!(stringUtils.hasSuffix "darwin" system))
              (with pkgs; [
                cryptsetup
                parted
              ]);
          in
            commonPackages ++ linuxPackages;
        };
      };
    };
}
