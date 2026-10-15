# Release de MCP for Blender (PyPI `mcp-for-blender`, ex-`blender-mcp`)
# partagée par le serveur (home/modules/code/ia/mcp.nix) et l'add-on
# (home/modules/blender.nix) : les deux viennent du même wheel, donc ne
# peuvent pas diverger. Bump : version + sha256 du .whl lus sur
# https://pypi.org/pypi/mcp-for-blender/json, puis `nix hash convert`.
{
  version = "2.1.8";
  wheelUrl = "https://files.pythonhosted.org/packages/b3/50/00959d2ce72d2f7fee9df8d69645f5ec8800a04d222a063142a4b7d570aa/mcp_for_blender-2.1.8-py3-none-any.whl";
  wheelHash = "sha256-GWqC0XLGmZFbdyb0l8zbMEMGSzUZ078NizSLWzgTVQI=";
}
