{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "zabrze";
  version = "0.7.3";
  src = fetchFromGitHub {
    owner = "Ryooooooga";
    repo = "zabrze";
    rev = "v${version}";
    hash = "sha256-OmwU7/SQqEAzZo7/Eix3yc+VLEU6+/NIiALvpU3PlKA=";
  };
  cargoHash = "sha256-9UZSOXTWvX9jPE0crGb/hUpemuVhEGgyzs+HL3QwIgg=";
  # テストが Linux の Nix sandbox で zsh パスを解決できず失敗するためスキップ
  doCheck = false;
  meta = with lib; {
    description = "Zsh abbreviation expansion plugin";
    homepage = "https://github.com/Ryooooooga/zabrze";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
