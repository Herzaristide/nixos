{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # sops-nix reads its decryption keys from the host's SSH ed25519 host key,
  # converted to an age identity at runtime. The mapping host SSH key → age
  # public key is declared in ../.sops.yaml.
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # On impermanence hosts, /var/lib/sops-nix lives under /persist via the
      # whitelist in modules/impermanence.nix (already included as /var/lib/* coverage).
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = false;
    };

    # Each secret declared here is decrypted at activation into
    # /run/secrets/<name>, owned by root unless overridden.
    # `neededForUsers = true` makes the secret available before user creation,
    # required when using it as `hashedPasswordFile`.
    secrets = {
      "passwords/root" = {
        neededForUsers = true;
      };
      "passwords/aristide" = {
        neededForUsers = true;
      };
    };
  };
}
