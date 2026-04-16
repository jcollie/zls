{
  callPackage,
  lib,
  stdenv,
  stdenvNoCC,
  zig,
  zlsVersionShort,
  zlsVersionFull,
  ...
}:
let
  fs = lib.fileset;
  target = builtins.replaceStrings [ "darwin" ] [ "macos" ] stdenv.hostPlatform.system;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zls";
  version = zlsVersionShort;
  src = fs.toSource {
    root = ./.;
    fileset = fs.intersection (fs.fromSource (lib.sources.cleanSource ./.)) (
      fs.unions [
        ./src
        ./tests
        ./build.zig
        ./build.zig.zon
        ./deps.nix
      ]
    );
  };
  deps = callPackage ./deps.nix { name = "zls-cache-${finalAttrs.version}"; };
  nativeBuildInputs = [ zig ];
  dontSetZigDefaultFlags = true;
  doCheck = true;
  zigBuildFlags = [
    "--system"
    "${finalAttrs.deps}"
    "-Dtarget=${target}"
    "-Dcpu=baseline"
    "-Doptimize=ReleaseSafe"
    "-Dversion-string=${zlsVersionFull}"
  ];
  zigCheckFlags = finalAttrs.zigBuildFlags ++ [ "test" ];
  meta = {
    license = lib.licenses.mit;
    mainProgram = "zls";
  };
})
