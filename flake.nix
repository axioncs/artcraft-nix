{
  description = "ArtCraft Crafting Apps: source and .deb packages";

  nixConfig = {
    extra-substituters = [ "https://artcraft-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "artcraft-nix.cachix.org-1:v9VqEk5AUclIqU2uaeWTNZOse05p4z2Lq7TJjiu7jM0="
    ];
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      apps = builtins.fromJSON (builtins.readFile ./apps.json);

      mkPackages = p:
        let
          mk = import ./lib.nix { pkgs = p; };
          per = name: a: {
            "${name}-src" = mk.src name a;
            "${name}-deb" = mk.deb name a;
            "${name}" = mk.deb name a;
          };
        in
        p.lib.foldl' (acc: n: acc // per n apps.${n}) { } (builtins.attrNames apps);
    in {
      packages.${system} = mkPackages pkgs;
      overlays.default = final: prev: { artcraft = mkPackages final; };
    };
}
