{ pkgs, ... }:

{
  # Code formatters (pour autofmt plugin de micro, et autres éditeurs)
  home.packages = with pkgs; [
    nixfmt # Nix
    prettier # JS/TS/JSON/YAML/Markdown/HTML/CSS
    ruff # Python (linter + formatter, remplace black)
    shfmt # Shell scripts
    rustfmt # Rust
    gofumpt # Go (stricter superset of gofmt)
  ];
}
