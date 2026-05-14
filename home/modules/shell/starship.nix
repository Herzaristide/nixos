{ ... }:

{
  # Config statique : starship n'utilise que des noms ANSI (`red`, `bright-black`…).
  # wezterm remappe le slot ANSI red (slot 1) vers la couleur d'accent vive
  # (template wezterm-accent.lua.tmpl) — c'est aussi le slot que Claude Code
  # utilise en thème `dark-ansi`, donc l'accent reste cohérent partout.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "\${custom.folder_size} ◆ $directory$git_status$git_branch$fill \${custom.docker} ◆ \${custom.disk}\n$character";

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

      character = {
        success_symbol = "[❅](bold red)";
        error_symbol = "[❅](bold red)";
      };

      custom.folder_size = {
        command = "ls -lA . 2>/dev/null | awk 'NR>1 && !/^d/ {s+=$5} END {if(s>=1073741824) printf \"%.1fG\",s/1073741824; else if(s>=1048576) printf \"%.1fM\",s/1048576; else printf \"%.0fK\",s/1024}'";
        when = "true";
        format = "[$output]($style)";
        style = "red";
      };

      custom.disk = {
        command = "df -h . | awk 'NR==2 {n=$1; sub(\".*/\",\"\",n); s=toupper(substr(n,1,4)); print s \"#\" $5}'";
        when = "true";
        format = "[$output]($style)";
        style = "red";
      };

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
