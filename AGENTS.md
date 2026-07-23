# AGENTS.md — NixOS Configuration Guide for AI Agents

> Host: sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## Project Overview

This is a NixOS system configuration based on **Nix Flakes**, employing a modular design and integrating **Home Manager** to manage user configurations.

- **System Upgrade Records (2026-07-23)**:
  - **FHS Environment Configuration**: Added `fhs.nix` based on `buildFHSEnv` to provide a standard Linux FHS sandbox environment for executing unpatched third-party binaries and SDKs without requiring `patchelf`.

- **System Upgrade Records (2026-07-14)**:
  - **SOPS-Nix Secrets Overhaul**: Permanently deleted the plain-text local `secrets.nix` file. Configured `sops-nix` utilizing the host's SSH host key (`/etc/ssh/ssh_host_ed25519_key`) and the user's personal key (`~/.ssh/id_ed25519`) as age decryption identities.
  - **Runtime Config Rendering**: Sensitive credentials (such as VLESS Outbounds) are encrypted in `secrets.yaml`. At boot/activation time, `sops-nix` decrypts them and dynamically renders `xray-away.json` into `/run/secrets/rendered/xray-away.json` (RAMFS). This protects credentials from being stored in the world-readable `/nix/store`.
  - **Variable Decoupling**: Moved non-sensitive values (`username`, `email`, public SSH keys) into a new public `common.nix` file which is tracked in git.
  - **Oh My Pi (omp) integration**: Packaged the `oh-my-pi` AI coding agent using a dynamic loader wrapper solution since traditional `patchelf` breaks Bun JS payloads. Published it to `sgnur-packages` and imported it declaratively via overlays.

- **System Upgrade Records (2026-07-13)**:
  - Decoupled software packages by migrating GUI applications to Home Manager.
  - Introduced the `home/lib.nix` helper library for unified dotfile management.
  - Fixed XDG subdirectory path mapping logic.

## Directory Structure

```
/etc/nixos/
├── flake.nix                    # Flake entry point
├── configuration.nix            # Main configuration (imports only)
├── common.nix                   # Public system & user variables
├── fhs.nix                      # Standalone FHS sandbox environment (buildFHSEnv)
├── .sops.yaml                   # SOPS recipient key configs
├── secrets.yaml                 # SOPS encrypted secrets (xray outbounds, etc.)
├── modules/                     # NixOS system modules
│   ├── desktop/                 # Desktop environment (niri/cosmic/audio/fonts)
│   ├── packages/                # Core system packages
│   ├── services/                # System services (ssh/greetd/xray/univpn/storage)
│   └── system/                  # System base configuration (boot/locale/network/nix/users)
├── home/                        # Home Manager configuration
│   ├── home.nix                 #   HM entry point
│   ├── lib.nix                  #   Shared helper library (e.g., mkDotfileLinks)
│   ├── packages/                #   User-level package management
│   └── programs/                #   Modular program configurations
└── dotfiles/                    # Symlink source configuration files
```

## Common Commands

```bash
# Build and switch system configuration
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos

# Launch FHS environment for unpatched binaries
nix-shell /etc/nixos/fhs.nix

# Edit encrypted secrets file
nix-shell -p sops --run "sops secrets.yaml"

# Check user service status
systemctl --user status dms.service
```

## Dotfiles Deployment Logic

- All user configurations are stored in the `dotfiles/` directory.
- XDG symlinks are created via the `mkDotfileLinks` helper function defined in `home/lib.nix`.
- Modifying files inside `dotfiles/` does not require a rebuild; applications will pick up changes automatically.
- **Note**: If a conflict occurs during building due to existing `*.backup` files, clean up the conflicting `~/.config/<program>/*.backup` files.

## Secrets Disaster Recovery (Key Rotation / Re-keying)

If you reinstall NixOS or move to a new machine, the system host key (`/etc/ssh/ssh_host_ed25519_key`) will change. As long as you have backed up your personal user key (`~/.ssh/id_ed25519`), you can easily recover and re-encrypt the secrets:

1. Restore your personal key to `/home/sgnay/.ssh/id_ed25519`.
2. Generate the new `age` public key from the new machine's SSH host key:
   ```bash
   nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
   # Output: age1...
   ```
3. Update the `&host` public key entry in `/etc/nixos/.sops.yaml` with the new age key.
4. Run the SOPS update keys command to decrypt the file using your personal key and re-encrypt it with the new host key:
   ```bash
   nix-shell -p sops --run "sops updatekeys secrets.yaml"
   ```
5. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#sgnixos
   ```

## Important Notes

- **Secrets Management**: Do NOT write plaintext secrets in git. Always edit `secrets.yaml` using the `sops` wrapper. Non-sensitive settings belong in `common.nix`.
- `allowUnfree` is enabled globally inside Home Manager; no additional setup is required.
