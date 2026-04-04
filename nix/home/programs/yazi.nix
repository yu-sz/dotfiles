{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    initLua = ./yazi-init.lua;
    plugins = {
      inherit (pkgs.yaziPlugins) smart-enter starship full-border;
    };
    flavors = {
      tokyo-night = pkgs.fetchFromGitHub {
        owner = "BennyOe";
        repo = "tokyo-night.yazi";
        rev = "8e6296f";
        hash = "sha256-LArhRteD7OQRBguV1n13gb5jkl90sOxShkDzgEf3PA0=";
      };
    };
    theme = {
      flavor = {
        use = "tokyo-night";
        dark = "tokyo-night";
      };
    };
    settings = {
      mgr = {
        sort_by = "natural";
        show_hidden = true;
        title_format = "";
      };
    };
    extraPackages = with pkgs; [
      ffmpeg
      poppler-utils
      imagemagick
      resvg
      _7zz
    ];
  };
}
