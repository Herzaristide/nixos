{ pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;
    settings = {
      theme = "dark-ansi";
      language = "French";
      model = "opus";
      voiceEnabled = true;
      voice = {
        enabled = true;
        mode = "hold";
      };
    };
  };
}
