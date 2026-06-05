{ ... }:

{
  # mpv — terminal media player; rubberband gives cleaner time-stretch at low speeds
  # (useful for practising a passage at 50% without pitch artefacts).
  programs.mpv = {
    enable = true;
    config = {
      af = "rubberband";
      keep-open = "yes";
      hr-seek = "yes";
      osd-bar = "yes";
      save-position-on-quit = "yes";
    };
  };
}
