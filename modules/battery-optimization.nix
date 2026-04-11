# Battery optimization module for laptops
# Optimizes CPU frequency scaling, NVIDIA power management, and thermal control
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Disable power-profiles-daemon (conflicts with auto-cpufreq/TLP)
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Auto-cpufreq: Automatic CPU frequency scaling optimized for laptops
  # More intelligent than TLP for modern processors (dynamic adjustment)
  services.auto-cpufreq = {
    enable = true;
    settings = {
      # Battery mode: aggressive power saving
      battery = {
        governor = "powersave";
        turbo = "never"; # Disable CPU turbo boost to reduce heat and power draw
        scaling_min_freq = 800000; # 800 MHz minimum
        scaling_max_freq = 2400000; # Cap at 2.4 GHz (adjust based on your CPU)
        enable_thresholds = true;
      };

      # AC mode: balanced performance
      charger = {
        governor = "performance";
        turbo = "auto";
        scaling_min_freq = 1200000;
        scaling_max_freq = 4000000; # Allow full speed when plugged in
      };
    };
  };

  # Thermald: Intel thermal management (prevents overheating, reduces fan noise)
  services.thermald.enable = true;

  # Laptop mode tools: aggressive disk power management
  # Reduces disk access to save power (increases commit intervals)
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave"; # Fallback governor if auto-cpufreq fails
    powertop.enable = true; # Enable powertop auto-tune on boot (optimizes USB, SATA, etc.)
  };
}
