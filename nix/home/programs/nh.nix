{ username, ... }:
{
  programs.nh = {
    enable = true;
    darwinFlake = "/Users/${username}/Projects/dotfiles";
  };
}
