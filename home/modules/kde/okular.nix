{ pkgs, ... }:

{
  home.packages = [ pkgs.kdePackages.okular ];

  xdg.configFile."okularpartrc".force = true;
  xdg.configFile."okularpartrc".text = ''
    [General]
    ShowLeftPanel=false
  '';

  xdg.configFile."okularrc".force = true;
  xdg.configFile."okularrc".text = ''
    [MainWindow]
    MenuBar=Disabled
  '';
}
