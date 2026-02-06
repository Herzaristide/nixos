{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = lib.concatStrings [
        "$directory"
        "[>](fg:#ef4444 bg:#991b1b)"
        "$git_branch"
        "$git_status"
        "[>](fg:#991b1b bg:#7f1d1d)"
        "$time"
        "[>](fg:#7f1d1d bg:#450a0a)"
        "[>](fg:#450a0a)"
        "\n$character"
      ];

      directory = {
        style = "fg:#fef2f2 bg:#ef4444";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      git_branch = {
        symbol = "git";
        style = "bg:#991b1b";
        format = "[[ $symbol $branch ](fg:#fca5a5 bg:#991b1b)]($style)";
      };

      git_status = {
        style = "bg:#991b1b";
        format = "[[($all_status$ahead_behind )](fg:#fca5a5 bg:#991b1b)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#450a0a";
        format = "[[  $time ](fg:#fca5a5 bg:#450a0a)]($style)";
      };

      character = {
        success_symbol = "[>](fg:#991b1b)";
        error_symbol = "[>](fg:#991b1b)";
      };
    };
  };
}
