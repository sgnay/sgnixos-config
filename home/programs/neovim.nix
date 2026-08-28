# home/programs/neovim.nix — Neovim + LazyVim 配置
{ pkgs, ... }:
let
  # LazyVim 启动配置
  lazyvimInit = pkgs.writeText "lazyvim-init.lua" ''
    -- 本地代理探活：仅当 127.0.0.1:1080 可达时才启用代理环境变量
    -- （代理关闭时首次 clone lazy.nvim 会因走死代理而失败/挂起）
    local function proxyAlive(host, port)
      local ok, conn = pcall(vim.loop.new_tcp)
      if not ok or not conn then
        return false
      end
      local alive, done = false, false
      conn:connect(host, port, function(err)
        alive = err == nil
        done = true
        conn:close()
      end)
      -- vim.wait 会驱动事件循环，让 connect 回调执行（最多等 2s）
      vim.wait(2000, function() return done end, 50)
      if not done then
        pcall(function() conn:close() end)
      end
      return alive
    end

    if proxyAlive("127.0.0.1", 1080) then
      local proxy_url = "http://127.0.0.1:1080"
      vim.env.GIT_HTTP_PROXY = proxy_url
      vim.env.GIT_HTTPS_PROXY = proxy_url
      vim.env.HTTP_PROXY = proxy_url
      vim.env.HTTPS_PROXY = proxy_url
      vim.env.ALL_PROXY = proxy_url
    end

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

    -- 禁用默认全局复制到系统剪贴板
    -- （注意：LazyVim 会在 VeryLazy 事件触发时强制将 clipboard 设为 unnamedplus，因此必须用 autocmd 锁死）
    vim.opt.clipboard = ""
    vim.api.nvim_create_autocmd("VimEnter", {
      pattern = "*",
      callback = function()
        vim.opt.clipboard = ""
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        vim.opt.clipboard = ""
      end,
    })
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "clipboard",
      callback = function()
        if #vim.opt.clipboard:get() > 0 then
          vim.opt.clipboard = ""
        end
      end,
    })

    -- 仅按快捷键时复制/剪切/粘贴到系统剪贴板 (+)
    local keymap = vim.keymap.set
    keymap({ "n", "v" }, "<leader>y", '"+y', { desc = "复制到系统剪贴板" })
    keymap("n", "<leader>Y", '"+Y', { desc = "复制整行到系统剪贴板" })
    keymap({ "n", "v" }, "<leader>d", '"+d', { desc = "剪切到系统剪贴板" })
    keymap({ "n", "v" }, "<leader>p", '"+p', { desc = "从系统剪贴板粘贴" })
    keymap({ "n", "v" }, "<leader>P", '"+P', { desc = "从系统剪贴板向前粘贴" })
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
}
