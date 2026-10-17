# VMs de dev génériques (modules/devbox.nix), par hôte : on y clone ce qu'on veut.
# Ajouter une VM : une entrée sous son hôte, puis rebuild de cet hôte (la VM) et
# des autres machines (alias `ssh <vm>` et nom `<vm>` résolu). `ip` = dernier
# octet dans le sous-réseau de l'hôte, unique ; chaque hôte a son sous-réseau,
# annoncé sur le tailnet.
{
  # 30 Go : 4 × 6 Go + ~8 Go pour l'hôte (ingestion GPU de thot comprise). Avec le
  # ballooning, une VM au repos rend sa RAM inutilisée.
  gary = {
    subnet = "10.42.0";
    vms = {
      dev1 = {
        ip = 2;
        mem = 6144;
        vcpu = 4;
      };
      dev2 = {
        ip = 3;
        mem = 6144;
        vcpu = 4;
      };
      dev3 = {
        ip = 4;
        mem = 6144;
        vcpu = 4;
      };
      dev4 = {
        ip = 5;
        mem = 6144;
        vcpu = 4;
      };
    };
  };

}
