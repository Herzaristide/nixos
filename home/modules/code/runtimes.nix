{ pkgs, ... }:

{
  # Runtimes et toolchains de développement.
  # `nodejs_22` est aligné sur la version utilisée par les serveurs MCP
  # (voir ./ia/mcp.nix) pour éviter de tirer deux versions de Node.
  home.packages = with pkgs; [
    # JavaScript / TypeScript
    nodejs_22
    corepack_22 # pnpm / yarn à la demande (corepack enable)
    bun
    deno

    # Java
    jdk21 # OpenJDK 21 LTS (javac, java, jar, jshell)
    maven
    gradle

    # Python
    python3
    uv # gestionnaire de paquets / venv rapide (remplace pip+venv+pipx)

    # Go
    go
    gopls

    # Rust
    rustc
    cargo
    rust-analyzer

    # C / C++
    gcc
    gnumake
    cmake
    pkg-config
  ];
}
