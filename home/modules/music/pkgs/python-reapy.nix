# python-reapy (MIT) — absent de nixpkgs. Pont Python vers l'API de REAPER,
# utilisé des deux côtés : dans le Python embarqué de REAPER (le serveur
# reapy, voir ../daw.nix) et par le serveur MCP `reaper` (client, épinglé
# sur la même version dans home/modules/code/ia/mcp.nix). Wheel pur Python.
# Bump : https://pypi.org/pypi/python-reapy/json, puis `nix hash convert`.
{
  buildPythonPackage,
  fetchurl,
  psutil,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "python-reapy";
  version = "0.10.0";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/dc/13/7e9af0cfab53087bf824b0b541aca14e52ddf61e74c2e134f20177acda76/python_reapy-${version}-py2.py3-none-any.whl";
    hash = "sha256-yTq3syy8dOmI1fQ6wvDweZd1Upp4UELhqKxZ7W6d2vQ=";
  };

  dependencies = [
    psutil
    typing-extensions
  ];

  pythonImportsCheck = [ "reapy" ];
}
