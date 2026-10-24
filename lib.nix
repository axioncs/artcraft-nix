{ pkgs }:
let
  inherit (pkgs) lib;
  h = x: if x == "" then lib.fakeHash else x;
  runtimeLibs = with pkgs; [
    wayland libxkbcommon libGL vulkan-loader fontconfig freetype
    alsa-lib openssl libx11 libxcursor libxi libxrandr libxcb zlib
    stdenv.cc.cc.lib
  ];
in {
  src = name: a:
    let pname = a.pname or name; in
    pkgs.rustPlatform.buildRustPackage {
      inherit pname;
      version = a.version;
      src = pkgs.fetchFromGitHub {
        owner = "storytold";
        repo = a.repo or name;
        rev = "v${a.version}";
        hash = h a.srcHash;
      };
      cargoHash = h a.cargoHash;
      cargoBuildFlags = [ "-p" pname ];
      doCheck = false;
      nativeBuildInputs = with pkgs; [ pkg-config makeWrapper ];
      buildInputs = runtimeLibs;
      postFixup = ''
        for b in $out/bin/*; do
          wrapProgram $b --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
        done
      '';
      meta.mainProgram = pname;
    };

  deb = name: a:
    let pname = a.pname or name; repo = a.repo or name; in
    pkgs.stdenv.mkDerivation {
      inherit pname;
      version = a.version;
      src = pkgs.fetchurl {
        url = "https://github.com/storytold/${repo}/releases/download/v${a.version}/${pname}-${a.version}-linux-x86_64.deb";
        hash = h a.debHash;
      };
      nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook ];
      buildInputs = runtimeLibs;
      runtimeDependencies = runtimeLibs;
      unpackPhase = "dpkg-deb -x $src .";
      installPhase = ''
        mkdir -p $out
        cp -r usr/* $out/
        substituteInPlace $out/share/applications/*.desktop \
          --replace-quiet /usr/bin $out/bin
      '';
      meta.mainProgram = pname;
    };
}
