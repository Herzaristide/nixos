# music21 (MIT, cuthbertLab) — absent de nixpkgs. Représentation symbolique
# de la musique : Claude y compose (voix, tessitures, articulations) puis
# exporte en MusicXML, MIDI ou LilyPond. Wheel pur Python.
# Bump : version + sha256 du .whl lus sur https://pypi.org/pypi/music21/json,
# puis `nix hash convert --hash-algo sha256 --to sri <hex>`.
{
  buildPythonPackage,
  fetchurl,
  chardet,
  joblib,
  jsonpickle,
  matplotlib,
  more-itertools,
  numpy,
  requests,
  webcolors,
}:

buildPythonPackage rec {
  pname = "music21";
  version = "10.5.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/be/a3/4948b2326e5957d54e3a754ee66d23d44126996986bb31eb47e22d06df9b/music21-${version}-py3-none-any.whl";
    hash = "sha256-26hpbq+rcJokS28YxkOZ7czPTpbd0eDk3n7/CikcLew=";
  };

  dependencies = [
    chardet
    joblib
    jsonpickle
    matplotlib
    more-itertools
    numpy
    requests
    webcolors
  ];

  pythonImportsCheck = [ "music21" ];
}
