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
      # Use a custom module to show number of running Docker containers on the right
      format = "$directory$git_status$git_branch$fill${"$"}{custom.disk} ${"$"}{custom.docker}\n$character";

      directory = {
        format = "[◆ $path]($style) ";
        style = "red";
        truncate_to_repo = true;
        truncation_length = 1;
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        style = "red";
        symbol = "";
        truncation_length = 8;
        truncation_symbol = "…";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style)) ";
        style = "red";
      };

      fill = {
        symbol = " ";
      };

      character = {
        success_symbol = "[&](bold red)";
        error_symbol = "[&](bold red)";
      };

      # Custom module: current disk mount point and usage
      custom.disk = {
        command = "df -h . | awk 'NR==2 {print $6 \" \" $3 \"/\" $2}'";
        format = "[💾 $output]($style)";
        style = "red";
      };

      # Custom module: number of running Docker containers
      custom.docker = {
        command = "docker ps -q 2>/dev/null | wc -l | tr -d ' '";
        when = "docker ps -q 2>/dev/null | grep -q .";
        format = "[🐳 $output]($style)";
        style = "red";
        disabled = false;
      };
    };
  };
}
