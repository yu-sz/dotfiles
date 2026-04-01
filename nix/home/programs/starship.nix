_: {
  programs.starship = {
    enable = true;
    settings = {
      format = "[░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)[](bg:#3B6ADB fg:#a3aed2)$directory[](fg:#3B6ADB bg:#394260)$git_branch$git_status$git_state[](fg:#394260 bg:#212736)$nodejs$bun$lua[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)
$character";
      directory = {
        style = "fg:#e3e5e5 bg:#3B6ADB";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };
      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };
      git_state = {
        disabled = false;
        style = "bg:#394260";
        format = "[[(\ )](fg:#769ff0 bg:#394260)]($style)";
        rebase = "󰡒 ";
        merge = " ";
        revert = " ";
        cherry_pick = "🍒";
        bisect = "";
        am = "";
        am_or_rebase = "";
      };
      git_status = {
        style = "bg:#394260";
        format = "[[(\ )](fg:#769ff0 bg:#394260)]($style)";
        conflicted = "⚡️";
        ahead = "";
        behind = "";
        diverged = "";
        up_to_date = "✓";
        untracked = "";
        stashed = "";
        modified = "🔥";
        staged = "";
        renamed = "";
        deleted = "";
      };
      nodejs = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol (\) ](fg:#769ff0 bg:#212736)]($style)";
      };
      bun = {
        symbol = "🥟 ";
        style = "bg:#212736";
        format = "[[ $symbol (\) ](fg:#769ff0 bg:#212736)]($style)";
      };
      lua = {
        symbol = "󰢱 ";
        style = "bg:#212736";
        format = "[[ $symbol (\) ](fg:#769ff0 bg:#212736)]($style)";
      };
      time = {
        disabled = true;
        time_format = "%R";
        style = "bg:#1d2230";
        format = "[[  \ ](fg:#a0a9cb bg:#1d2230)]($style)";
      };
    };
  };
}
