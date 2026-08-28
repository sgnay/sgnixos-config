# AGENTS.md — NixOS Configuration Guide for AI Agents

> Host: sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## System Overview

Modular NixOS system managed via **Nix Flakes** with **Home Manager** integrated.

- **Secrets Management**: Managed by `sops-nix`. Age keys are derived from the host SSH key (`/etc/ssh/ssh_host_ed25519_key`) and user SSH key (`~/.ssh/id_ed25519`). Secrets in `secrets.yaml` are rendered at boot to `/run/secrets/rendered/` (RAMFS).
- **Dotfiles & Symlinks**: User configs live in `dotfiles/` and are linked out-of-store via `mkDotfileLinks` helper (`home/lib.nix`). Direct edits in `dotfiles/` apply immediately without rebuilds.
- **FHS Sandbox**: Use `nix-shell /etc/nixos/fhs.nix` (`buildFHSEnv`) to run unpatched third-party Linux binaries without `patchelf`.
- **Packaging Guidelines**: GUI apps launched via desktop launchers MUST be wrapped using `makeWrapper` (setting `LD_LIBRARY_PATH` & `XDG_DATA_DIRS`) and registered declaratively in Home Manager. Do NOT use `nix-shell` inside `.desktop` `Exec` fields.

## Core Rules for AI Agents

1. **NEVER run `nixos-rebuild switch`**: AI agents are **STRICTLY PROHIBITED** from running `sudo nixos-rebuild switch` or any system-switching commands. Agents should only modify configuration files and test/verify builds (e.g. `nix build .#nixosConfigurations.sgnixos.config.system.build.toplevel`). System switching is left to the user.
2. **Secrets Decryption**: `sops` defaults to looking for `id_rsa`. For `id_ed25519`, set `SOPS_AGE_KEY` via `ssh-to-age` before invoking `sops`:
   ```bash
   USER_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519") SOPS_AGE_KEY="$USER_KEY" nix-shell -p sops --run "sops secrets.yaml"
   ```
3. **No Plaintext Secrets**: Never write plaintext credentials in git files. Store public settings in `common.nix` and encrypted secrets in `secrets.yaml`.

## Project Structure

```
/etc/nixos/
├── flake.nix                    # Flake entry point & module imports
├── configuration.nix            # System-level entry point (minimal imports)
├── common.nix                   # Public system & user variables
├── fhs.nix                      # Standalone FHS environment (buildFHSEnv)
├── .sops.yaml                   # SOPS recipient age keys configuration
├── secrets.yaml                 # SOPS encrypted secret database
├── statix.toml                  # Statix (Nix linter) configuration
├── upgrade-version.sh           # NixOS/Home-Manager version bump helper
├── ConfigInit/                  # Legacy (non-flake) init scaffold for fresh installs
├── modules/                     # NixOS system modules
│   ├── desktop/                 # Niri / Cosmic / Audio / Fonts
│   ├── packages/                # Core system packages & virtualization
│   ├── services/                # Network, storage, SSH, Xray services
│   └── system/                  # Boot, locale, network, user management
├── home/                        # Home Manager configuration
│   ├── home.nix                 # Home Manager entry point
│   ├── lib.nix                  # Helper library (mkDotfileLinks)
│   ├── packages/                # User applications and wrappers
│   └── programs/                # Modular program configs (git, niri, neovim, etc.)
└── dotfiles/                    # Source configuration files (symlinked)
```

## Common Commands

```bash
# Verify system build (Dry build without switching)
nix build .#nixosConfigurations.sgnixos.config.system.build.toplevel

# Edit encrypted secrets file
USER_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519") SOPS_AGE_KEY="$USER_KEY" nix-shell -p sops --run "sops secrets.yaml"

# Launch FHS environment
nix-shell /etc/nixos/fhs.nix

# Check active user services
systemctl --user status dms.service
# Manual cleanup
ls -l /nix/var/nix/{gcroots,profiles}
sudo ln -s $(readlink -f /nix/var/nix/gcroots/keep-system-1) /nix/var/nix/profiles/system-1-link
sudo ln -s $(readlink -f /nix/var/nix/profiles/system-2-link) /nix/var/nix/gcroots/keep-system-2
nix-collect-garbage -d
sudo nix-collect-garbage -d
sudo nix store gc
sudo nix store optimise
# Check what prevents garbage collection
nix-store --gc --print-roots
```

## Key Rotation & Disaster Recovery

- **Rotating User SSH Key (`~/.ssh/id_ed25519`)**:
  1. Generate new key: `ssh-keygen -t ed25519 -C "sgnay@outlook.com" -f ~/.ssh/id_ed25519 -N ""`
  2. Compute age public key: `nix-shell -p ssh-to-age --run "ssh-to-age < ~/.ssh/id_ed25519.pub"`
  3. Update `user-public-ssh-keys` in `common.nix` and `&user` in `.sops.yaml`.
  4. Update `secrets.yaml`:
     ```bash
     OLD_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519.old") SOPS_AGE_KEY="$OLD_KEY" nix-shell -p sops --run "sops updatekeys secrets.yaml -y"
     ```

- **Host Key Replacement (`/etc/ssh/ssh_host_ed25519_key`)**:
  1. Compute new host age key: `nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"`
  2. Update `&host` in `.sops.yaml`.
  3. Resync `secrets.yaml`:
     ```bash
     USER_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519") SOPS_AGE_KEY="$USER_KEY" nix-shell -p sops --run "sops updatekeys secrets.yaml -y"
     ```
