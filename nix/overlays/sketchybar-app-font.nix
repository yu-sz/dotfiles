{
  stdenvNoCC,
  fetchurl,
  lib,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sketchybar-app-font";
  version = "2.0.60";

  src = fetchurl {
    url = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v${finalAttrs.version}/sketchybar-app-font.ttf";
    hash = "sha256-pVGsLKxtxpybnHpN6orFLxfgWy1Nb/oyo5fboTeBLk4=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 "$src" "$out/share/fonts/truetype/sketchybar-app-font.ttf"
    runHook postInstall
  '';

  meta = {
    description = "Ligature-based symbol font for SketchyBar app icons";
    homepage = "https://github.com/kvndrsslr/sketchybar-app-font";
    license = lib.licenses.cc0;
    platforms = lib.platforms.all;
  };
})
