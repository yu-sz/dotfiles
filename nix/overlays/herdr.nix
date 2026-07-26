{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.7.5";
  hashes = {
    aarch64-darwin = "sha256-NzUFRrABJVWUO5Lq+WJmXeTiZDlbrrRCJ7gBXo/1sNY=";
    x86_64-darwin = "sha256-P+UMSmPcgQIwaxMiF4Yo3bNlXNOuVteE8JQVNAjWnmI=";
    x86_64-linux = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
    aarch64-linux = "sha256-MudjoUmaa2lLHXCOTwYrdDvh2p80/PpNIS1ttv4JqLk=";
  };
  assets = {
    aarch64-darwin = "herdr-macos-aarch64";
    x86_64-darwin = "herdr-macos-x86_64";
    x86_64-linux = "herdr-linux-x86_64";
    aarch64-linux = "herdr-linux-aarch64";
  };
  system = stdenvNoCC.hostPlatform.system;
  asset = assets.${system} or (throw "herdr: unsupported platform ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "herdr";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/${asset}";
    hash = hashes.${system};
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://github.com/ogulcancelik/herdr";
    changelog = "https://github.com/ogulcancelik/herdr/releases/tag/v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.attrNames assets;
    mainProgram = "herdr";
  };
}
