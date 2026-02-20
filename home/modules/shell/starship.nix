{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # Clean format matching fastfetch red theme
      format = "$directory$git_branch$git_status$character";

      directory = {
        format = "[◆ $path]($style) ";
        style = "red";
        truncate_to_repo = false;
        use_os_path_sep = true;
        # Show full absolute path including home directory
        fish_style_pwd_dir_length = 0;
        # Don't use ~ symbol, show full path
        home_symbol = "/home/aristide/";
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        style = "red";
        symbol = "";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style)) ";
        style = "red";
      };

      character = {
        success_symbol = "[>](bold red)";
        error_symbol = "[>](bold red)";
      };
    };
  };
}
