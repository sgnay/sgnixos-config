# services/greetd.nix — 轻量登录管理器（ReGreet 图形科幻玻璃风格登录界面）
{ config, pkgs, ... }:
let
  userName = (import ../../secrets.nix).username;
  bgPath = "${pkgs.cosmic-wallpapers}/share/backgrounds/cosmic/tarantula_nebula_nasa_PIA23646.jpg";

  # ===== 科幻玻璃态 CSS =====
  sciFiCss = ''
    /* ═══════════════════════════════════════════════╗
       ║  ReGreet — 科幻玻璃态 (Sci-Fi Glassmorphism) ║
       ╚══════════════════════════════════════════════╝ */

    /* ---- 色彩变量 ---- */
    @define-color glass-bg          rgba(8, 8, 30, 0.30);
    @define-color glass-border      rgba(80, 160, 255, 0.25);
    @define-color glass-border-glow rgba(80, 160, 255, 0.15);
    @define-color neon-blue         #50a0ff;
    @define-color neon-cyan         #00e5ff;
    @define-color neon-glow         rgba(80, 160, 255, 0.3);
    @define-color text-primary      rgba(220, 235, 255, 0.95);
    @define-color text-secondary    rgba(180, 200, 230, 0.7);
    @define-color input-bg          rgba(12, 12, 40, 0.50);

    /* ---- 窗口底层（微妙的深空渐变覆盖） ---- */
    window {
      background: linear-gradient(
        135deg,
        rgba(0, 0, 0, 0.0) 0%,
        rgba(10, 0, 30, 0.25) 50%,
        rgba(0, 20, 40, 0.15) 100%
      );
    }

    /* ---- 主登录面板（玻璃态） ---- */
    frame.background {
      background: @glass-bg;
      backdrop-filter: blur(24px) saturate(1.4);
      -gtk-outline-bottom-left-radius: 18px;
      -gtk-outline-bottom-right-radius: 18px;
      -gtk-outline-top-left-radius: 18px;
      -gtk-outline-top-right-radius: 18px;
      border: 1px solid @glass-border;
      padding: 6px;
      box-shadow:
        0 8px 40px rgba(0, 0, 0, 0.5),
        inset 0 1px 0 rgba(255, 255, 255, 0.06),
        0 0 30px @glass-border-glow;
      transition: all 0.3s ease;
    }

    /* 登录面板光晕动画 */
    @keyframes panelGlow {
      0%, 100% { box-shadow: 0 8px 40px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.06), 0 0 20px rgba(80,160,255,0.12); }
      50%      { box-shadow: 0 8px 40px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.06), 0 0 35px rgba(80,160,255,0.22); }
    }
    frame.background {
      animation: panelGlow 4s ease-in-out infinite;
    }

    /* ---- 顶端时钟面板 ---- */
    #clock_frame {
      background: @glass-bg;
      backdrop-filter: blur(20px) saturate(1.3);
      border: 1px solid @glass-border;
      border-top: none;
      border-top-right-radius: 0px !important;
      border-top-left-radius: 0px !important;
      padding: 10px 28px;
      box-shadow:
        0 4px 20px rgba(0, 0, 0, 0.3),
        inset 0 1px 0 rgba(255, 255, 255, 0.06);
    }
    #clock_frame label {
      font-family: "JetBrains Mono", "Orbitron", monospace;
      font-size: 28px;
      font-weight: 600;
      letter-spacing: 3px;
      color: @neon-cyan;
      text-shadow: 0 0 10px rgba(0, 229, 255, 0.5), 0 0 30px rgba(0, 229, 255, 0.15);
    }

    /* ---- 问候语 ---- */
    #message_label {
      font-family: "Orbitron", sans-serif;
      font-size: 14px;
      font-weight: 400;
      letter-spacing: 2px;
      text-transform: uppercase;
      color: @text-primary;
      text-shadow: 0 0 8px @neon-glow;
    }

    /* ---- 标签（User: / Session:） ---- */
    label {
      color: @text-secondary;
      font-family: "Orbitron", sans-serif;
      font-size: 12px;
      letter-spacing: 1px;
      text-transform: uppercase;
    }

    /* ---- 下拉框 / 输入框 ---- */
    combobox {
      min-height: 38px;
    }
    combobox button {
      background: @input-bg;
      color: @text-primary;
      border: 1px solid rgba(80, 160, 255, 0.2);
      border-radius: 10px;
      padding: 4px 12px;
      font-family: "JetBrains Mono", monospace;
      font-size: 14px;
      transition: all 0.2s ease;
      box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.2);
    }
    combobox button:hover {
      border-color: @glass-border;
      background: rgba(20, 20, 60, 0.6);
    }
    combobox button:focus {
      border-color: @neon-blue;
      box-shadow: 0 0 12px @neon-glow, inset 0 1px 2px rgba(0,0,0,0.2);
      outline: none;
    }

    /* ---- 密码输入框 ---- */
    entry, passwordentry {
      background: @input-bg;
      color: @text-primary;
      caret-color: @neon-cyan;
      border: 1px solid rgba(80, 160, 255, 0.2);
      border-radius: 10px;
      padding: 6px 14px;
      font-family: "JetBrains Mono", monospace;
      font-size: 15px;
      min-height: 36px;
      transition: all 0.2s ease;
      box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.3);
    }
    entry:hover, passwordentry:hover {
      border-color: rgba(80, 160, 255, 0.4);
      background: rgba(16, 16, 52, 0.6);
    }
    entry:focus, passwordentry:focus {
      border-color: @neon-blue;
      background: rgba(16, 16, 52, 0.7);
      box-shadow:
        0 0 12px @neon-glow,
        inset 0 1px 3px rgba(0, 0, 0, 0.3);
      outline: none;
    }

    /* ---- 密码输入框的 placeholder ---- */
    entry:placeholder-text, passwordentry:placeholder-text {
      color: rgba(180, 200, 230, 0.3);
      font-style: normal;
    }

    /* ---- 登录按钮（发光动画） ---- */
    @keyframes btnPulse {
      0%, 100% {
        box-shadow: 0 0 8px rgba(80, 160, 255, 0.4), 0 0 20px rgba(80, 160, 255, 0.15);
      }
      50% {
        box-shadow: 0 0 12px rgba(80, 160, 255, 0.6), 0 0 30px rgba(80, 160, 255, 0.25);
      }
    }
    button.suggested-action {
      background: linear-gradient(135deg, rgba(40, 100, 220, 0.7), rgba(20, 60, 160, 0.7));
      color: white;
      border: 1px solid rgba(80, 160, 255, 0.5);
      border-radius: 10px;
      padding: 8px 28px;
      font-family: "Orbitron", sans-serif;
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 2px;
      text-transform: uppercase;
      transition: all 0.3s ease;
      box-shadow: 0 0 8px rgba(80, 160, 255, 0.4), 0 0 20px rgba(80, 160, 255, 0.15);
    }
    button.suggested-action:hover {
      background: linear-gradient(135deg, rgba(60, 130, 250, 0.8), rgba(30, 80, 200, 0.8));
      border-color: rgba(80, 180, 255, 0.7);
      box-shadow: 0 0 15px rgba(80, 160, 255, 0.6), 0 0 35px rgba(80, 160, 255, 0.3);
    }
    button.suggested-action:active {
      background: linear-gradient(135deg, rgba(30, 80, 200, 0.9), rgba(10, 40, 120, 0.9));
    }

    /* ---- 取消按钮 ---- */
    #cancel_button {
      background: rgba(255, 255, 255, 0.05);
      color: @text-secondary;
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 10px;
      padding: 8px 20px;
      font-family: "Orbitron", sans-serif;
      font-size: 11px;
      letter-spacing: 1px;
      transition: all 0.2s ease;
    }
    #cancel_button:hover {
      background: rgba(255, 255, 255, 0.1);
      border-color: rgba(255, 255, 255, 0.2);
    }

    /* ---- 用户/会话切换按钮 ---- */
    togglebutton {
      background: @input-bg;
      color: @text-secondary;
      border: 1px solid rgba(80, 160, 255, 0.15);
      border-radius: 10px;
      padding: 2px 8px;
      min-width: 32px;
      min-height: 32px;
      transition: all 0.2s ease;
    }
    togglebutton:hover {
      background: rgba(20, 20, 60, 0.6);
      border-color: rgba(80, 160, 255, 0.3);
    }
    togglebutton:checked {
      background: rgba(30, 80, 200, 0.4);
      border-color: @neon-blue;
      box-shadow: 0 0 8px @neon-glow;
    }

    /* ---- 重启/关机按钮 ---- */
    button.destructive-action {
      background: rgba(255, 255, 255, 0.06);
      color: @text-secondary;
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 10px;
      padding: 6px 18px;
      font-family: "Orbitron", sans-serif;
      font-size: 11px;
      letter-spacing: 1px;
      text-transform: uppercase;
      transition: all 0.3s ease;
      backdrop-filter: blur(8px);
      min-width: 120px;
    }
    button.destructive-action:hover {
      background: rgba(255, 60, 60, 0.15);
      border-color: rgba(255, 80, 80, 0.3);
      color: #ff6060;
      box-shadow: 0 0 12px rgba(255, 60, 60, 0.2);
    }
    button.destructive-action:active {
      background: rgba(255, 60, 60, 0.25);
    }

    /* ---- 错误提示条 ---- */
    infobar {
      background: rgba(200, 40, 40, 0.2);
      border: 1px solid rgba(255, 80, 80, 0.3);
      border-radius: 12px;
      backdrop-filter: blur(16px);
    }
    infobar label {
      color: #ff8080;
      font-family: "JetBrains Mono", monospace;
      font-size: 13px;
    }

    /* ---- 密码可见性切换图标 ---- */
    passwordentry > button {
      background: transparent;
      border: none;
      color: @text-secondary;
    }
    passwordentry > button:hover {
      color: @text-primary;
    }

    /* ---- Grid 内部间距微调 ---- */
    grid {
      border-spacing: 10px;
    }

    /* ---- 全局焦点指示器（移除 GTK 默认虚线框，用 glow 替代） ---- */
    *:focus-visible {
      outline: none;
      box-shadow: 0 0 0 2px rgba(80, 160, 255, 0.5);
    }
  '';
in
{
  # === ReGreet 配置（programs.regreet 模块接管 greetd + cage 启动） ===
  programs.regreet = {
    enable = true;

    # GTK 主题 — Catppuccin-Mocha 深色（作为基础主题，CSS 覆盖其样式）
    theme = {
      package = pkgs.catppuccin-gtk;
      name = "Catppuccin-Mocha";
    };

    # 图标主题
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    # 光标主题
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };

    # 字体 — Orbitron 科幻感无衬线 + JetBrains Mono 等宽代码风
    font = {
      package = pkgs.orbitron;
      name = "Orbitron";
      size = 16;
    };

    # 配置 TOML
    settings = {
      background = {
        path = bgPath;
        fit = "Cover";
      };
      appearance = {
        greeting_msg = "✦  SYSTEM ACCESS  ✦";
        # 可选："SECTOR-7G // AUTHENTICATION REQUIRED"
        #      "✦  NEURAL INTERFACE  ✦"
        #      "ENTER THE GRID"
      };
      widget.clock = {
        format = "%a %H:%M:%S";
        resolution = "500ms";
      };
      commands = {
        reboot = [ "systemctl" "reboot" ];
        poweroff = [ "systemctl" "poweroff" ];
      };
    };

    # 注入科幻玻璃态 CSS
    extraCss = sciFiCss;

    # cage 参数：-s 单窗口模式，-d 无装饰
    cageArgs = [ "-s" "-d" ];
  };

  # 安装 Orbitron 字体到系统（供 GTK CSS 引用）
  fonts.packages = [ pkgs.orbitron ];

  # 创建 greeter 用户（模块需要此用户存在才能启动）
  users.users.greeter = {
    isSystemUser = true;
    home = "/var/lib/greeter";
    createHome = true;
    group = "greeter";
    extraGroups = [ "video" ];
  };
  users.groups.greeter = { };
}
