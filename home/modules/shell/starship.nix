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

      # Simple format: directory, git info, and prompt
      format = "$directory$git_branch$git_status$character";

      directory = {
        format = "[$path]($style) ";
        style = "blue";
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      git_branch = {
        format = "on [$symbol$branch]($style) ";
        style = "green";
        symbol = "";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style)) ";
        style = "yellow";
      };

      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };
    };
  };
}
