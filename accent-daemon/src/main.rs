mod appctl;
mod color;
mod protocol;
mod state;
mod templates;

use appctl::{AppCtlOptions, reload_all};
use protocol::{Command, Response};
use state::AppState;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{UnixListener, UnixStream};
use tokio::sync::broadcast;

// ── Entry point ───────────────────────────────────────────────────────────

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();

    let mut init_mode = false;
    let mut no_hyprctl = false;
    let mut socket_path: Option<String> = None;

    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--init" => init_mode = true,
            "--no-hyprctl" => no_hyprctl = true,
            "--socket" => {
                i += 1;
                socket_path = args.get(i).cloned();
            }
            _ => {}
        }
        i += 1;
    }

    let accent_dir = accent_dir();
    let app_state = AppState::load(accent_dir);

    let opts = AppCtlOptions { no_hyprctl };

    if init_mode {
        // One-shot: render templates + fire reloads, then exit.
        // Used by home-manager accentSeed activation.
        run_init(&app_state, &opts);
        return;
    }

    // Daemon mode
    let socket = socket_path.unwrap_or_else(default_socket_path);
    // Remove stale socket from a previous run
    let _ = std::fs::remove_file(&socket);

    let listener = match UnixListener::bind(&socket) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("paletted: cannot bind socket {socket}: {e}");
            std::process::exit(1);
        }
    };
    eprintln!("paletted: listening on {socket}");

    // Perform initial render so all config files are up to date on daemon start
    run_init(&app_state, &opts);

    // Shared state behind a mutex — modified when set_accent / set_mode arrive
    let shared = Arc::new(Mutex::new(app_state));

    // Broadcast channel for Watch subscribers
    let (tx, _) = broadcast::channel::<String>(32);
    let tx = Arc::new(tx);

    loop {
        match listener.accept().await {
            Ok((stream, _)) => {
                let shared = Arc::clone(&shared);
                let tx = Arc::clone(&tx);
                let no_hyprctl = no_hyprctl;
                tokio::spawn(async move {
                    handle_connection(stream, shared, tx, no_hyprctl).await;
                });
            }
            Err(e) => eprintln!("paletted: accept error: {e}"),
        }
    }
}

// ── Connection handler ────────────────────────────────────────────────────

async fn handle_connection(
    stream: UnixStream,
    shared: Arc<Mutex<AppState>>,
    tx: Arc<broadcast::Sender<String>>,
    no_hyprctl: bool,
) {
    let (reader, mut writer) = stream.into_split();
    let mut lines = BufReader::new(reader).lines();

    let line = match lines.next_line().await {
        Ok(Some(l)) => l,
        _ => return,
    };

    let cmd: Command = match serde_json::from_str(&line) {
        Ok(c) => c,
        Err(e) => {
            let resp = Response::err(format!("parse error: {e}"));
            let _ = write_response(&mut writer, &resp).await;
            return;
        }
    };

    match cmd {
        Command::GetState => {
            let state_snapshot = shared.lock().unwrap().to_palette_state();
            let resp = Response::ok(state_snapshot);
            let _ = write_response(&mut writer, &resp).await;
        }

        Command::SetAccent { color } => {
            let result = {
                let mut state = shared.lock().unwrap();
                match crate::color::Color::from_hex(&color) {
                    Some(c) => {
                        state.accent = c;
                        apply_change(&state, no_hyprctl)
                    }
                    None => Err(format!("invalid hex color: {color}")),
                }
            };
            match result {
                Ok(snapshot) => {
                    // Broadcast to Watch subscribers
                    let event_json =
                        serde_json::to_string(&Response::changed(snapshot.clone()))
                            .unwrap_or_default();
                    let _ = tx.send(event_json);

                    let resp = Response::ok(snapshot);
                    let _ = write_response(&mut writer, &resp).await;
                }
                Err(e) => {
                    let resp = Response::err(e);
                    let _ = write_response(&mut writer, &resp).await;
                }
            }
        }

        Command::SetMode { mode } => {
            let result = {
                let mut state = shared.lock().unwrap();
                if mode != "dark" && mode != "light" {
                    Err(format!("invalid mode: {mode} (expected dark or light)"))
                } else {
                    state.mode = mode;
                    apply_change(&state, no_hyprctl)
                }
            };
            match result {
                Ok(snapshot) => {
                    let event_json =
                        serde_json::to_string(&Response::changed(snapshot.clone()))
                            .unwrap_or_default();
                    let _ = tx.send(event_json);

                    let resp = Response::ok(snapshot);
                    let _ = write_response(&mut writer, &resp).await;
                }
                Err(e) => {
                    let resp = Response::err(e);
                    let _ = write_response(&mut writer, &resp).await;
                }
            }
        }

        Command::SetPaletteColor { key, color, mode } => {
            const VALID_KEYS: &[&str] = &[
                "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07",
                "base08", "base09", "base0a", "base0b", "base0c", "base0d", "base0e", "base0f",
            ];
            let result = {
                let mut state = shared.lock().unwrap();
                if !VALID_KEYS.contains(&key.as_str()) {
                    Err(format!("invalid palette key: {key}"))
                } else {
                    match crate::color::Color::from_hex(&color) {
                        Some(c) => {
                            let target = mode.as_deref().unwrap_or(&state.mode).to_string();
                            if target == "light" {
                                state.palette_light.insert(key, c.to_hex());
                            } else {
                                state.palette_dark.insert(key, c.to_hex());
                            }
                            apply_change(&state, no_hyprctl)
                        }
                        None => Err(format!("invalid hex color: {color}")),
                    }
                }
            };
            match result {
                Ok(snapshot) => {
                    let event_json =
                        serde_json::to_string(&Response::changed(snapshot.clone()))
                            .unwrap_or_default();
                    let _ = tx.send(event_json);
                    let resp = Response::ok(snapshot);
                    let _ = write_response(&mut writer, &resp).await;
                }
                Err(e) => {
                    let resp = Response::err(e);
                    let _ = write_response(&mut writer, &resp).await;
                }
            }
        }

        Command::Watch => {
            // Send current state immediately, then forward broadcasts.
            let state_snapshot = shared.lock().unwrap().to_palette_state();
            let initial = serde_json::to_string(&Response::ok(state_snapshot)).unwrap_or_default();
            if writer.write_all(initial.as_bytes()).await.is_err() {
                return;
            }
            if writer.write_all(b"\n").await.is_err() {
                return;
            }

            let mut rx = tx.subscribe();
            loop {
                match rx.recv().await {
                    Ok(msg) => {
                        if writer.write_all(msg.as_bytes()).await.is_err() {
                            break;
                        }
                        if writer.write_all(b"\n").await.is_err() {
                            break;
                        }
                    }
                    Err(broadcast::error::RecvError::Closed) => break,
                    Err(broadcast::error::RecvError::Lagged(_)) => continue,
                }
            }
        }
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────

/// Save state to disk, render all templates, and fire live-reload signals.
/// Returns the serializable state snapshot on success.
fn apply_change(state: &AppState, no_hyprctl: bool) -> Result<protocol::PaletteState, String> {
    state.save().map_err(|e| format!("save failed: {e}"))?;
    templates::render_all(state).map_err(|e| format!("render failed: {e}"))?;
    reload_all(state, &AppCtlOptions { no_hyprctl });
    Ok(state.to_palette_state())
}

fn run_init(state: &AppState, opts: &AppCtlOptions) {
    if let Err(e) = state.save() {
        eprintln!("paletted: --init save failed: {e}");
    }
    if let Err(e) = templates::render_all(state) {
        eprintln!("paletted: --init render failed: {e}");
    }
    reload_all(state, opts);
}

async fn write_response(
    writer: &mut tokio::net::unix::OwnedWriteHalf,
    resp: &Response,
) -> std::io::Result<()> {
    let json = serde_json::to_string(resp)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
    writer.write_all(json.as_bytes()).await?;
    writer.write_all(b"\n").await
}

fn accent_dir() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    PathBuf::from(home).join(".config/accent")
}

fn default_socket_path() -> String {
    let runtime_dir = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/run/user/1000".into());
    format!("{runtime_dir}/paletted.sock")
}
