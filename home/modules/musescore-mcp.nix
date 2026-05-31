{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "ghchen99";
    repo = "mcp-musescore";
    rev = "828eb9be5acce90072d7301c81bea9efe0514354";
    hash = "sha256-mig1hSABip+V1pGBDEqGiXLQDk24KfqXYs8Vq1zLsdY=";
  };

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.mcp
    ps.websockets
  ]);

  serverBin = pkgs.writeShellScriptBin "musescore-mcp-server" ''
    exec ${pythonEnv}/bin/python ${src}/server.py "$@"
  '';

  # nixpkgs build MuseScore sans api.websocketserver (MUSE_MODULE_NETWORK_WEBSOCKET=OFF
  # par défaut). Le plugin QML ci-dessus en dépend, donc on rebuild MuseScore
  # avec ce flag et qtwebsockets.
  musescoreWithWebsocket = pkgs.musescore.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.kdePackages.qtwebsockets ];
    cmakeFlags = old.cmakeFlags ++ [ "-DMUSE_MODULE_NETWORK_WEBSOCKET=ON" ];
  });
in
{
  # QML plugin loaded by MuseScore. Enable it once via:
  #   MuseScore → Plugins → Plugin Manager → cocher "MuseScore API Server"
  # Puis avant chaque session :
  #   MuseScore → Plugins → MuseScore API Server (lance le WebSocket)
  home.file."Documents/MuseScore4/Plugins/musescore-mcp-websocket.qml" = {
    source = "${src}/musescore-mcp-websocket.qml";
    force = true;
  };

  home.packages = [
    serverBin
    musescoreWithWebsocket
  ];

  programs.mcp.servers.musescore = {
    command = "${serverBin}/bin/musescore-mcp-server";
    type = "stdio";
  };
}
