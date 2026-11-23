{ anna, ... }:

# Les classements Apple du globe de karenine (panels/Globe.qml, sur un
# bureau vide) : chaque matin, `anna world prefetch` va chercher ceux des
# 237 pays (ebooks payants et gratuits, livres audio, musique), les
# couvertures des livres et la fiche de chaque entrée (résumé, prix,
# extrait), dans ~/.cache/karenine/world/. Le globe lit ce cache toute la
# journée ; ce qui manque, il le demande lui-même, plus lentement.
#
# Le service d'Apple est lent et instable : le passage procède par vagues
# et prend une vingtaine de minutes (cf. anna/src/world.rs dans karenine).
# Son journal : journalctl --user -u karenine-world.
{
  systemd.user.services.karenine-world = {
    Unit.Description = "Classements Apple du globe de karenine (anna world prefetch)";
    Service = {
      Type = "oneshot";
      ExecStart = "${anna}/bin/anna world prefetch";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.karenine-world = {
    Unit.Description = "Classements Apple du globe de karenine, chaque matin";
    Timer = {
      OnCalendar = "*-*-* 06:00";
      # Machine éteinte à 6 h : le passage se fait au démarrage suivant.
      Persistent = true;
      RandomizedDelaySec = "10min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
