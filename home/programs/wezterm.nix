# home/programs/wezterm.nix — WezTerm 终端配置（可变符号链接）
{ config, lib, pkgs, ... }:
let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
  link = name: { source = mkLink "/etc/nixos/dotfiles/wezterm/${name}"; };
in
{
  home.packages = with pkgs; [ fish jetbrains-mono wqy_zenhei fira-code ];

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

  xdg.configFile = {
    "wezterm/appearance.lua"          = link "appearance.lua";
    "wezterm/behavior.lua"            = link "behavior.lua";
    "wezterm/window.lua"              = link "window.lua";
    "wezterm/keymaps.lua"             = link "keymaps.lua";
    "wezterm/colors/dank-theme.toml"  = link "colors/dank-theme.toml";
  };
}
