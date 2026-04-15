{ pkgs, ... }:

{
  # Walker launcher + elephant history backend
  home.packages = [
    pkgs.walker
    pkgs.elephant
  ];

  # Start elephant daemon for walker history
  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant history daemon for Walker";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."walker/config.toml".text = ''
    [ui]
      fullscreen = false
      width = 800

    [search]
      delay = 0

    [[modules]]
      name = "applications"
      placeholder = "Applications"
      history = true
      switcher_only = false

    [[modules]]
      name = "runner"
      placeholder = "Run"
      history = true

    [[modules]]
      name = "windows"
      placeholder = "Windows"
  '';

  xdg.configFile."walker/style.css".text = ''
    #window {
      background: rgba(0, 0, 0, 0.87);
      border: 3px solid #D90202;
      border-radius: 30px;
    }

    #search {
      color: #33D4C4;
      font-family: "MonoidNerdFont";
      font-size: 15px;
      padding: 15px 30px;
      border-bottom: 2px solid #D90202;
      background: transparent;
    }

    #search:focus {
      outline: none;
    }

    #typeahead {
      color: rgba(51, 212, 196, 0.4);
    }

    #list {
      padding: 10px 0;
    }

    #item {
      color: #33D4C4;
      padding: 8px 30px;
      border-radius: 0;
    }

    #item:selected {
      background: white;
      color: #D90202;
      border-radius: 30px;
      margin: 0 10px;
    }

    #label {
      font-family: "MonoidNerdFont";
      font-size: 14px;
    }

    #sub {
      font-family: "MonoidNerdFont";
      font-size: 11px;
      opacity: 0.6;
    }
  '';
}
