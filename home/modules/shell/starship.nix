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

    settings = lib.mkDefault {
      "$schema" = "https://starship.rs/config-schema.json";

      # Clean format matching fastfetch red theme
      # Use a custom module to show number of running Docker containers on the right
      format = "${"$"}{custom.folder_size} ◆ $directory$git_status$git_branch$fill ${"$"}{custom.docker} ◆ ${"$"}{custom.disk}\n$character";

      directory = {
        format = "[$path]($style) ";
        style = "red";
        truncate_to_repo = true;
        truncation_length = 1;
        home_symbol = "aristide";
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        style = "bright-black";
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

      character = lib.mkDefault {
        success_symbol = "[❅](bold red)";
        error_symbol = "[❅](bold red)";
      };

      # Custom module: size of the current folder
      custom.folder_size = {
        command = "ls -lA . 2>/dev/null | awk 'NR>1 && !/^d/ {s+=$5} END {if(s>=1073741824) printf \"%.1fG\",s/1073741824; else if(s>=1048576) printf \"%.1fM\",s/1048576; else printf \"%.0fK\",s/1024}'";
        when = "true";
        format = "[$output]($style)";
        style = "red";
      };

      # Custom module: current disk mount point and usage
      custom.disk = {
        command = "df -h . | awk 'NR==2 {n=$1; sub(\".*/\",\"\",n); s=toupper(substr(n,1,4)); print s \"#\" $5}'";
        when = "true";
        format = "[$output]($style)";
        style = "red";
      };

      # Custom module: number of running Docker containers
      custom.docker = {
        command = "docker ps -q 2>/dev/null | wc -l | tr -d ' '";
        when = "docker ps -q 2>/dev/null | grep -q .";
        format = "[$output]($style)";
        style = "red";
        disabled = false;
      };
    };
  };
}
