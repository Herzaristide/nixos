{ ... }:

{
  # Config statique : starship n'utilise que des noms ANSI (`red`, `bright-black`…).
  # alacritty remappe le slot ANSI red (slot 1) vers la couleur d'accent vive
  # (template alacritty.toml.tmpl) — c'est aussi le slot que Claude Code
  # utilise en thème `dark-ansi`, donc l'accent reste cohérent partout.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # `\n` avant $character → prompt sur deux lignes : les infos en haut, la
      # saisie (et le symbole ✦) sur la ligne du dessous.
      format = "\${custom.disk} ◆ $directory$git_status$git_metrics$git_branch\n$character ";

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

      git_metrics = {
        disabled = false;
        format = "[+$added]($added_style)[/-$deleted]($deleted_style) ";
        added_style = "red";
        deleted_style = "bright-black";
      };

      character = {
        success_symbol = "[✦](bold red)";
        error_symbol = "[✦](bold red)";
      };

      custom.disk = {
        command = "df -h . | awk 'NR==2 {print $5}'";
        when = "true";
        format = "[$output]($style)";
        style = "red";
      };
    };
  };
}
