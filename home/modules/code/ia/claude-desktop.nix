{ pkgs, inputs, ... }:

{
  # Application de bureau officielle (chat + Cowork + Claude Code dans une
  # fenêtre), repackagée depuis le .deb d'Anthropic : voir pkgs/claude-desktop.
  # Elle apporte son propre .desktop (com.anthropic.Claude.desktop) et son
  # icône, donc rien à déclarer ici — le handler `claude://` est câblé dans
  # home/head.nix.
  #
  # Cowork isole chaque session d'agent dans une micro-VM, ce qui tire qemu et
  # OVMF : ~3 Go de closure en plus. `withCowork = false` les retire et ne
  # dégrade que cette fonctionnalité.
  home.packages = [
    (inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop.override {
      withCowork = true;
    })
  ];
}
