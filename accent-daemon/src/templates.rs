use crate::state::AppState;
use std::collections::HashMap;
use std::fs;
use std::io;
use std::path::PathBuf;

/// Render all templates and write output files.
pub fn render_all(state: &AppState) -> io::Result<()> {
    let subs = build_substitutions(state);
    let home = home_dir();

    let templates: &[(&str, PathBuf)] = &[
        ("hyprland.conf.tmpl", state.accent_dir.join("hyprland.conf")),
        ("starship.toml.tmpl", state.accent_dir.join("starship.toml")),
        (
            "fastfetch-full.jsonc.tmpl",
            state.accent_dir.join("fastfetch-full.jsonc"),
        ),
        (
            "fastfetch-logo.jsonc.tmpl",
            state.accent_dir.join("fastfetch-logo.jsonc"),
        ),
        (
            "micro.tmpl",
            home.join(".config/micro/colorschemes/accent.micro"),
        ),
        (
            "wezterm-accent.lua.tmpl",
            home.join(".config/wezterm/wezterm.lua"),
        ),
        (
            "vesktop-quickcss.css.tmpl",
            home.join(".config/vesktop/settings/quickCss.css"),
        ),
        ("gtk4.css.tmpl", home.join(".config/gtk-4.0/gtk.css")),
        ("kdeglobals.tmpl", home.join(".config/kdeglobals")),
        (
            "zen-userchrome.css.tmpl",
            home.join(".config/accent/zen-userchrome.css"),
        ),
        (
            "vscode-settings.json.tmpl",
            home.join(".config/Code/User/settings.json"),
        ),
    ];

    for (tmpl_name, out_path) in templates {
        let tmpl_path = state.template_dir.join(tmpl_name);
        if !tmpl_path.exists() {
            continue;
        }
        let content = fs::read_to_string(&tmpl_path)?;
        let rendered = apply_substitutions(&content, &subs);
        if let Some(parent) = out_path.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::write(out_path, rendered)?;
    }

    Ok(())
}

// ── Substitution map ──────────────────────────────────────────────────────

fn build_substitutions(state: &AppState) -> HashMap<String, String> {
    let accent = &state.accent;
    let palette = state.active_palette();

    let mut subs: HashMap<String, String> = HashMap::with_capacity(64);

    // Accent tokens
    subs.insert("@ACCENT@".into(), accent.to_hex());
    subs.insert("@ACCENT_DARK@".into(), accent.darker().to_hex());
    subs.insert("@ACCENT_MUTED@".into(), accent.muted().to_hex());
    subs.insert("@ACCENT_RGB@".into(), accent.to_rgb_str());
    subs.insert("@ACCENT_ANSI@".into(), accent.to_ansi());
    subs.insert("@HEX@".into(), accent.hex_no_hash());

    // Misc tokens baked in by accent.nix
    subs.insert("@LOGO_PATH@".into(), state.logo_path.clone());
    subs.insert("@ICONS_THEME@".into(), state.icons_theme.clone());

    // Palette base16 tokens — both `#rrggbb` and `r,g,b` RGB forms
    for (key, hex) in palette {
        // key is lowercase "base00" … "base0f"
        let upper = key.to_uppercase(); // BASE00 … BASE0F

        subs.insert(format!("@{upper}@"), hex.clone());

        if let Some(c) = crate::color::Color::from_hex(hex) {
            subs.insert(format!("@{upper}_RGB@"), c.to_rgb_str());
        }
    }

    subs
}

fn apply_substitutions(content: &str, subs: &HashMap<String, String>) -> String {
    let mut result = content.to_string();
    for (token, value) in subs {
        result = result.replace(token.as_str(), value.as_str());
    }
    result
}

fn home_dir() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| "/root".into()))
}
