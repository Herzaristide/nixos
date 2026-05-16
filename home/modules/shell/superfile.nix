{ ... }:

{
  # Blue theme — palette blues hardcoded so superfile always looks cohesive
  # with the rest of the NixOS blue aesthetic.
  xdg.configFile."superfile/theme/nixos-blue.toml".text = ''
    # NixOS Blue — static blue theme
    code_syntax_highlight = "nord"

    # ========= Border =========
    file_panel_border = "#2a2a3a"
    sidebar_border    = "#1a1a2a"
    footer_border     = "#2a2a3a"

    # ========= Border Active =========
    # "4" = ANSI blue, "12" = ANSI bright-blue — both remapped to the accent
    # color by Alacritty, so the theme follows paletted automatically.
    file_panel_border_active = "4"
    sidebar_border_active    = "12"
    footer_border_active     = "12"
    modal_border_active      = "4"

    # ========= Background =========
    full_screen_bg = "#0d0d0d"
    file_panel_bg  = "#0d0d0d"
    sidebar_bg     = "#0d0d0d"
    footer_bg      = "#0d0d0d"
    modal_bg       = "#1a1a2a"

    # ========= Foreground =========
    full_screen_fg = "#e0e0ff"
    file_panel_fg  = "#e0e0ff"
    sidebar_fg     = "#e0e0ff"
    footer_fg      = "#8a90b0"
    modal_fg       = "#e0e0ff"

    # ========= Special Color =========
    cursor  = "4"
    correct = "#44aa88"
    error   = "#cc4444"
    hint    = "12"
    cancel  = "#cc8844"
    gradient_color = ["4", "12"]

    # ========= File Panel Special Items =========
    file_panel_top_directory_icon = "12"
    file_panel_top_path           = "4"
    file_panel_item_selected_fg   = "12"
    file_panel_item_selected_bg   = "#1a1a2a"

    # ========= Sidebar Special Items =========
    sidebar_title            = "4"
    sidebar_item_selected_fg = "12"
    sidebar_item_selected_bg = "#1a1a2a"
    sidebar_divider          = "#2a2a3a"

    # ========= Modal Special Items =========
    modal_cancel_fg  = "#0d0d0d"
    modal_cancel_bg  = "#cc8844"
    modal_confirm_fg = "#0d0d0d"
    modal_confirm_bg = "#44aa88"

    # ========= Help Menu =========
    help_menu_hotkey = "12"
    help_menu_title  = "4"
  '';

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
      theme = "nixos-blue";
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
