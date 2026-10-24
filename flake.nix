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
      mk = import ./lib.nix { inherit pkgs; };
      apps = builtins.fromJSON (builtins.readFile ./apps.json);
      per = name: a: {
        "${name}-src" = mk.src name a;
        "${name}-deb" = mk.deb name a;
        "${name}" = mk.deb name a;
      };
    in {
      packages.${system} =
        pkgs.lib.foldl' (acc: n: acc // per n apps.${n}) { } (builtins.attrNames apps);
    };
}
