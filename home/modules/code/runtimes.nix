{ pkgs, ... }:

{
  # Runtimes, toolchains et formatters de développement.
  # `nodejs_22` est aligné sur la version utilisée par les serveurs MCP
  # (voir ./ia/mcp.nix) pour éviter de tirer deux versions de Node.
  home.packages = with pkgs; [
    # JavaScript / TypeScript
    nodejs_22

    bun
    deno
    prettier # JS/TS/JSON/YAML/Markdown/HTML/CSS

    # Java
    jdk25 # OpenJDK 25 LTS (javac, java, jar, jshell)
    maven
    gradle
    google-java-format

    # Python
    python3
    uv # gestionnaire de paquets / venv rapide (remplace pip+venv+pipx)
    ruff # linter + formatter (remplace black)
    pyright # LSP Python (langserver) — utilisé par le plugin LSP de Claude Code + Zed

    # Go
    go
    gopls
    gofumpt # formatter (stricter superset of gofmt)

    # Rust
    rustc
    cargo
    rust-analyzer
    rustfmt

    # C / C++
    gcc
    gnumake
    cmake
    pkg-config
    clang-tools # clang-format + clangd

    # Nix
    nixfmt
    nixd # LSP Nix (langserver)

    # Shell
    shfmt

    # QML (Quickshell — voir ../quickshell.nix)
    qt6.qtdeclarative # qmllint (lint) + qmlformat (formatter) + qmlls (LSP)
  ];
}
