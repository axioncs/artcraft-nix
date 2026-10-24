# artcraft-nix

Unofficial Nix packaging for the [ArtCraft](https://getartcraft.com/apps) Crafting Apps and the ArtCraft Launcher. Upstream: <https://github.com/storytold>.

The apps are early-stage (alpha) software. Expect bugs and missing features.

## Contents

- [Packages](#packages)
- [Try without installing](#try-without-installing)
- [Use in your own flake](#use-in-your-own-flake)
  - [NixOS: direct package reference](#nixos-direct-package-reference)
  - [NixOS: overlay](#nixos-overlay)
  - [Home Manager](#home-manager)
  - [nix profile](#nix-profile)
  - [Dev shell](#dev-shell)
- [Choosing between -deb and -src](#choosing-between--deb-and--src)
- [Binary cache](#binary-cache)
- [Pinning and updating](#pinning-and-updating)
- [Limitations](#limitations)
- [License](#license)

## Packages

Apps: `photocraft`, `vectorcraft`, `filmcraft`, `lightcraft`, `pdfcraft`, `effectcraft`, `designcraft`, `wordcraft`, `soundcraft`, `deckcraft`, `cadcraft`, `gridcraft`, `figcraft`, `artcraft-launcher`.

Every app `<name>` provides three outputs:

| Output | Description |
|---|---|
| `<name>-deb` | Upstream release `.deb`, unpacked and patched with autoPatchelf. Includes desktop file, icons and mime data. No compiling. |
| `<name>-src` | Built from the upstream source tag with `buildRustPackage`. Binaries only. |
| `<name>` | Alias for `<name>-deb`. |

Platform: `x86_64-linux`.

## Try without installing

```sh
nix run github:axioncs/artcraft-nix#vectorcraft
nix run github:axioncs/artcraft-nix#vectorcraft-src
```

## Use in your own flake

Add the input:

```nix
inputs.artcraft.url = "github:axioncs/artcraft-nix";
```

### NixOS: direct package reference

Recommended. Uses the exact builds CI caches.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    artcraft.url = "github:axioncs/artcraft-nix";
  };

  outputs = { nixpkgs, artcraft, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = with artcraft.packages.${pkgs.stdenv.hostPlatform.system}; [
            photocraft
            vectorcraft
          ];
        })
      ];
    };
  };
}
```

### NixOS: overlay

Exposes everything as `pkgs.artcraft.<name>`.

```nix
modules = [
  { nixpkgs.overlays = [ artcraft.overlays.default ]; }
  ({ pkgs, ... }: {
    environment.systemPackages = with pkgs.artcraft; [
      photocraft
      vectorcraft-src
    ];
  })
];
```

With the overlay, packages are built against your `pkgs`. The `-src` variants then differ from the CI builds and will not hit the binary cache.

### Home Manager

Standalone or as a NixOS module:

```nix
{ pkgs, inputs, ... }: {
  home.packages = [
    inputs.artcraft.packages.${pkgs.stdenv.hostPlatform.system}.photocraft
  ];
}
```

Pass `inputs` with `extraSpecialArgs = { inherit inputs; };` (standalone) or `home-manager.extraSpecialArgs` (NixOS module). Or add the overlay to `nixpkgs.overlays` and use `pkgs.artcraft.photocraft`.

### nix profile

```sh
nix profile add github:axioncs/artcraft-nix#photocraft
nix profile upgrade --all
```

### Dev shell

```nix
devShells.x86_64-linux.default = pkgs.mkShell {
  packages = [ artcraft.packages.x86_64-linux.pdfcraft ];
};
```

### About `follows`

Do not set `inputs.artcraft.inputs.nixpkgs.follows`. It changes the build inputs of the `-src` packages, so they no longer match the cached store paths and compile locally. The `-deb` packages are cheap either way.

## Choosing between -deb and -src

- `-deb`: use this day to day. Fast, includes desktop entries and icons, and ships the upstream-built binaries.
- `-src`: use it if you want builds from source. First build takes about 10 minutes per app unless it comes from the binary cache. Installs only the binaries.

## Binary cache

CI pushes the `-src` builds to Cachix. Add this to your NixOS config:

```nix
nix.settings = {
  extra-substituters = [ "https://artcraft-nix.cachix.org" ];
  extra-trusted-public-keys = [
    "artcraft-nix.cachix.org-1:v9VqEk5AUclIqU2uaeWTNZOse05p4z2Lq7TJjiu7jM0="
  ];
};
```

Nix ignores the flake's own `nixConfig` unless your user is a trusted user, so set it in the system config. You can also run `cachix use artcraft-nix` with the Cachix CLI.

## Pinning and updating

```sh
nix flake update artcraft                 # newest versions
nix flake lock --override-input artcraft github:axioncs/artcraft-nix/<commit>   # pin a commit
```

Versions are recorded in `apps.json`, so a flake lock pins exact app versions and hashes.

## Limitations

- `x86_64-linux` only.
- Not affiliated with ArtCraft or storytold.

## License

Packaging code: MIT (see `LICENSE`). The apps are upstream projects under their own licenses (MIT or Apache-2.0).
