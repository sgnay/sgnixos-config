# home/programs/wezterm.nix — WezTerm 终端配置（可变符号链接）
{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotfiles = import ../lib.nix { inherit lib config; };
in
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local final_config = {}
      local modules = { 'appearance', 'window', 'behavior', 'keymaps' }
      for _, module_name in ipairs(modules) do
        local ok, module_config = pcall(require, module_name)
        if ok then
          if module_config.keys then
            final_config.keys = final_config.keys or {}
            for _, keymap in ipairs(module_config.keys) do
              table.insert(final_config.keys, keymap)
            end
          end
          for k, v in pairs(module_config) do
            if k ~= 'keys' then final_config[k] = v end
          end
        end
      end
      return final_config
    '';
  };

  xdg.configFile =
    (dotfiles.mkDotfileLinks "wezterm" [
      "appearance.lua"
      "behavior.lua"
      "window.lua"
      "keymaps.lua"
    ])
    // (dotfiles.mkDotfileLinks "wezterm/colors" [
      "dank-theme.toml"
    ]);
}
