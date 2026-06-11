{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "salamander-grand-piano";
  version = "v3-20250729";

  src = pkgs.fetchFromGitHub {
    owner = "sfzinstruments";
    repo = "SalamanderGrandPiano";
    rev = "3382bf9496bba2486f5ab0de55a264d1dfc38404";
    sha256 = "0pvya3pq3csk390l5jiyr106b25cq536c2k64hxdb0n70gqy351y";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sfz/SalamanderGrandPiano
    cp -r * $out/share/sfz/SalamanderGrandPiano/
    runHook postInstall
  '';

  meta = {
    description = "Salamander Grand Piano V3 (Yamaha C5, SFZ) by Alexander Holm";
    homepage = "https://github.com/sfzinstruments/SalamanderGrandPiano";
    license = pkgs.lib.licenses.cc-by-30;
  };
}
