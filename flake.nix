{
  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    };

    zig-overlay = {
      url = "git+https://codeberg.org/jcollie/zig-overlay.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zon2nix = {
      url = "github:jcollie/zon2nix?ref=main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        zig.follows = "zig-overlay";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zig-overlay,
      zon2nix,
    }:
    let
      lib = nixpkgs.lib;
      parseVersionFieldFromZon =
        name:
        lib.pipe ./build.zig.zon [
          builtins.readFile
          (builtins.match ".*\n[[:space:]]*\\.${name}[[:space:]]=[[:space:]]\"([^\"]+)\".*")
          builtins.head
        ];
      zlsVersionShort = parseVersionFieldFromZon "version";
      zlsVersionFull =
        zlsVersionShort
        + (
          if (builtins.length (builtins.splitVersion zlsVersionShort)) == 3 then
            ""
          else
            "+" + lib.replaceString "-" "." (self.dirtyShortRev or self.shortRev)
        );
      zigPlatforms = lib.attrNames zig-overlay.packages;
    in
    builtins.foldl' lib.recursiveUpdate { } (
      map (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          formatter.${system} = pkgs.nixfmt;
          packages.${system} = {
            default = self.packages.${system}.zls;
            zls = pkgs.callPackage ./package.nix {
              inherit zlsVersionShort zlsVersionFull;
              zig = zig-overlay.packages.${system}."0.16.0";
            };
          };
          devShells.${system} = {
            default = pkgs.mkShell {
              name = "zls";
              buildInputs = [
                pkgs.nixfmt
                pkgs.pinact
                zig-overlay.packages.${system}."0.16.0"
                zon2nix.packages.${system}.zon2nix
              ];
            };
          };
        }
      ) zigPlatforms
    );
}
