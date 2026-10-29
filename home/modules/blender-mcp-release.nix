# Release de MCP for Blender (PyPI `mcp-for-blender`, ex-`blender-mcp`)
# partagée par le serveur (home/modules/code/ia/mcp.nix) et l'add-on
# (home/modules/blender.nix) : les deux viennent du même wheel, donc ne
# peuvent pas diverger. Bump : version + sha256 du .whl lus sur
# https://pypi.org/pypi/mcp-for-blender/json, puis `nix hash convert`.
{
  version = "2.2.6";
  wheelUrl = "https://files.pythonhosted.org/packages/e7/12/c8ac2cfa020bc03ded622bf45198c33fd221bd606c2544425637be667894/mcp_for_blender-2.2.6-py3-none-any.whl";
  wheelHash = "sha256-b0fO9qW14ghCafzewCf6jG+wlxV/G/Ms2SKnEeWdc4w=";
}
