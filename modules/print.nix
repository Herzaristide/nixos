{
  pkgs,
  ...
}:

{
  # Printing — CUPS + pilotes HP (hplip couvre les LaserJet/OfficeJet/DeskJet ;
  # les modèles récents passent aussi en IPP Everywhere sans pilote).
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };

  # Découverte mDNS/DNS-SD : indispensable pour qu'une imprimante réseau (Wi-Fi
  # ou Ethernet) apparaisse toute seule dans CUPS. `openFirewall` ouvre le
  # 5353/udp — le seul port que modules/network.nix laisse passer côté LAN.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    system-config-printer # GUI d'ajout d'imprimante (sinon http://localhost:631)
  ];
}
