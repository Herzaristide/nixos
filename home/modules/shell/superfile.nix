{ ... }:

{
  programs.superfile = {
    enable = true;

    # Écrit dans ~/.config/superfile/config.toml
    # En définissant un éditeur de terminal (micro), superfile ouvre l'éditeur
    # en fenêtre flottante superposée à son interface lorsqu'on presse `e`,
    # donnant l'impression de rester dans le même logiciel.
    #
    # NOTE : superfile exige que TOUS les champs soient présents dans
    # config.toml (sinon il refuse de démarrer). On reproduit donc ici la
    # totalité des champs par défaut, avec nos personnalisations.
    settings = {
      # --- Personnalisations ---
      theme = "default";
      editor = "micro";
      dir_editor = "micro";
      cd_on_quit = true;
      auto_check_update = false;
      zoxide_support = true;
      ignore_missing_fields = true;

      # --- Défauts complets (requis par superfile) ---
      code_previewer = "";
      default_directory = "~";
      default_sort_type = 0;
      sort_order_reversed = false;
      case_sensitive_sort = false;
      debug = false;
      default_open_file_preview = true;
      show_image_preview = true;
      show_panel_footer_info = false;
      file_size_use_si = false;
      shell_close_on_success = false;
      nerdfont = true;
      transparent_background = true;
      file_preview_width = 0;
      sidebar_width = 20;
      border_top = "─";
      border_bottom = "─";
      border_left = "│";
      border_right = "│";
      border_top_left = "╭";
      border_top_right = "╮";
      border_bottom_left = "╰";
      border_bottom_right = "╯";
      border_middle_left = "├";
      border_middle_right = "┤";
      enable_md5_checksum = false;
      image_preview_backend = "";
      metadata = true;
    };

    # Hotkeys : on laisse les défauts de superfile (`e` ouvre déjà l'éditeur).
    # Définir seulement quelques touches casse superfile car il exige un
    # fichier hotkeys.toml complet avec TOUS les champs.

    # Dossiers épinglés (signets/bookmarks) dans le panneau latéral
    pinnedFolders = [
      {
        name = "NixOS";
        location = "/etc/nixos";
      }
      {
        name = "Home";
        location = "/home/aristide";
      }
    ];
  };
}
