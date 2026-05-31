{ pkgs, ... }:

# Wyoming voice pipeline — three independent micro-daemons that together
# provide wake-word, STT and TTS. Each is a NixOS service that listens on
# a local TCP port and speaks the Wyoming JSON-over-TCP protocol.
#
#   :10400  openwakeword  → fires when "ok_nabu" / "hey_jarvis" is heard
#   :10300  faster-whisper → audio in, transcript out (French)
#   :10200  piper         → text in, audio out (fr_FR-siwis-medium voice)
#
# The orchestrator (still to be written) opens a socket to each of the
# three, chains them, and forwards the resulting transcript to Ollama.

{
  services.wyoming.faster-whisper.servers.fr = {
    enable = true;
    uri = "tcp://127.0.0.1:10300";
    model = "small-int8";
    language = "fr";
    device = "cpu";
  };

  services.wyoming.piper.servers.fr = {
    enable = true;
    uri = "tcp://127.0.0.1:10200";
    voice = "fr_FR-siwis-medium";
  };

  services.wyoming.openwakeword = {
    enable = true;
    uri = "tcp://127.0.0.1:10400";
    extraArgs = [
      "--preload-model"
      "ok_nabu"
    ];
  };

  environment.systemPackages = [ pkgs.python3 ];
}
