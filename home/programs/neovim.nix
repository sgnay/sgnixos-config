# home/programs/neovim.nix — Neovim + LazyVim 配置
{ config, pkgs, ... }:
let
  # LazyVim 启动配置
  lazyvimInit = pkgs.writeText "lazyvim-init.lua" ''
    -- 设置代理（国内 GitHub 直连困难）
    local proxy_url = "http://127.0.0.1:1080"
    vim.env.GIT_HTTP_PROXY = proxy_url
    vim.env.GIT_HTTPS_PROXY = proxy_url
    vim.env.HTTP_PROXY = proxy_url
    vim.env.HTTPS_PROXY = proxy_url
    vim.env.ALL_PROXY = proxy_url

    -- 设置 lazy.nvim 的安装路径
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)

    -- LazyVim 配置（按需启用 Nix 插件集）
    require("lazy").setup({
      -- 基础 LazyVim 发行版
      {
        "LazyVim/LazyVim",
        branch = "main",
        import = "lazyvim.plugins",
      },
      -- Nix 语言支持
      { import = "lazyvim.plugins.extras.lang.nix" },
      -- nil_ls 由 Nix 系统包提供，不让 Mason 重复安装
      {
        "neovim/nvim-lspconfig",
        opts = {
          servers = {
            nil_ls = {
              mason = false,
            },
          },
        },
      },
      -- 可选：markdown / json 等常用 extras
      { import = "lazyvim.plugins.extras.lang.markdown" },
      { import = "lazyvim.plugins.extras.lang.json" },
      -- 可选：自动补全增强
      { import = "lazyvim.plugins.extras.coding.blink" },
      -- 可选：编辑器界面增强
      { import = "lazyvim.plugins.extras.editor.mini-files" },
    }, {
      -- LazyVim 风格配置
      defaults = {
        lazy = true,
      },
      install = {
        colorscheme = { "catppuccin" },
      },
      checker = {
        enabled = false,  -- 不自动检查更新（Nix 管理版本）
      },
      performance = {
        cache = {
          enabled = true,
        },
        rtp = {
          disabled_plugins = {
            "gzip",
            "matchit",
            "matchparen",
            "netrwPlugin",
            "tarPlugin",
            "tohtml",
            "tutor",
            "zipPlugin",
          },
        },
      },
    })
  '';
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      # LazyVim 发行版核心
      lazy-nvim # 插件管理器
      LazyVim # LazyVim 发行版
    ];

    initLua = ''
      -- 加载 LazyVim 启动配置
      dofile(vim.fn.stdpath("config") .. "/lazyvim-init.lua")
    '';
  };

  xdg.configFile."nvim/lazyvim-init.lua".source = lazyvimInit;

  home.packages = with pkgs; [
    nil # Nix LSP
    nixfmt # Nix 格式化（RFC-style）
  ];
}

