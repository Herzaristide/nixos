{ ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
      preview = {
        max_width = 1000;
        max_height = 1000;
      };
    };

    # Couleurs interactives sur les ANSI 1 (red) et 9 (lightred),
    # remappées vers l'accent courant par Alacritty (cf. accent-daemon).
    # Les sections non listées gardent les défauts de yazi.
    theme = {
      mgr = {
        cwd = {
          fg = "red";
        };
        tab_active = {
          fg = "black";
          bg = "lightred";
        };
        tab_inactive = {
          fg = "white";
          bg = "darkgray";
        };
        border_style = {
          fg = "darkgray";
        };
        marker_marked = {
          fg = "lightred";
          bg = "lightred";
        };
        marker_selected = {
          fg = "lightred";
          bg = "lightred";
        };
      };

      # mgr.hovered / mgr.preview_hovered ont été déplacés ici dans yazi 26.x
      # (PR #3419) — c'est la surbrillance du fichier sous le curseur.
      indicator = {
        current = {
          fg = "black";
          bg = "red";
        };
        preview = {
          underline = true;
        };
      };

      mode = {
        normal_main = {
          fg = "black";
          bg = "lightred";
          bold = true;
        };
        normal_alt = {
          fg = "lightred";
          bg = "darkgray";
        };
      };

      status = {
        progress_normal = {
          fg = "red";
          bg = "black";
        };
      };

      select = {
        border = {
          fg = "red";
        };
        active = {
          fg = "lightred";
        };
      };

      input = {
        border = {
          fg = "red";
        };
      };

      completion = {
        border = {
          fg = "red";
        };
      };

      confirm = {
        border = {
          fg = "red";
        };
        title = {
          fg = "red";
        };
      };

      pick = {
        border = {
          fg = "red";
        };
        active = {
          fg = "lightred";
        };
      };

      which = {
        cand = {
          fg = "lightred";
        };
      };
    };
  };
}
