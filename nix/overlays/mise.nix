{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  mise,
}:
let
  sources = {
    aarch64-darwin = {
      platform = "macos-arm64";
      hash = "sha256-jrR25W9oCpNHzik0Z2jYQXT2MaN+Axd1ni4qVlgwyl0=";
    };
    x86_64-linux = {
      platform = "linux-x64-musl";
      hash = "sha256-2g2azl1bMyHjkfFfv4tT/NZbkCTmc+pRxVFRieWBBBY=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mise";
  version = "2026.10.17";

  src = fetchurl {
    url = "https://github.com/jdx/mise/releases/download/v${finalAttrs.version}/mise-v${finalAttrs.version}-${source.platform}.tar.xz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ installShellFiles ];
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/mise "$out/bin/mise"
    installManPage man/man1/mise.1
    "$out/bin/mise" completion bash > mise.bash
    "$out/bin/mise" completion fish > mise.fish
    "$out/bin/mise" completion zsh > _mise
    installShellCompletion --bash mise.bash --fish mise.fish --zsh _mise
    mkdir -p "$out/lib/mise"
    touch "$out/lib/mise/.disable-self-update"
    runHook postInstall
  '';

  meta = mise.meta // {
    changelog = "https://github.com/jdx/mise/releases/tag/v${finalAttrs.version}";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
