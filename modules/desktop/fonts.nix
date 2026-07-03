{ config, pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    fira-code              # WezTerm: "Fira Code"
    jetbrains-mono         # WezTerm: "JetBrains Mono"
    wqy_zenhei             # WezTerm: "WenQuanYi Zen Hei"
    wqy_microhei           # qqmusic 中文显示
    corefonts              # WPS 符号缺失修复 (Webdings, Arial, ...)
    symbola                # WPS Symbol 字体补充
    dejavu_fonts           # fontconfig 别名 Wingdings/MT Extra → DejaVu Sans
  ];

  # fontconfig 别名：
  #   1. Fira Code VF → FiraCode Nerd Font（WezTerm 兼容）
  #   2. Windows 字体 → 已安装字体（Electron 应用如 qqmusic 中文显示）
  #   3. WPS 符号字体 → 已有字体
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <!-- WezTerm 无法加载 fira-code VF 的 Regular 体重，映射到 Nerd Font -->
      <alias>
        <family>Fira Code</family>
        <prefer>
          <family>FiraCode Nerd Font</family>
        </prefer>
      </alias>

      <!-- Windows 中文字体 → WenQuanYi Micro Hei（qqmusic 等 Electron 应用） -->
      <alias>
        <family>Microsoft YaHei</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>Microsoft YaHei UI</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>Microsoft JhengHei</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>Microsoft JhengHei UI</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>SimHei</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>SimSun</family>
        <prefer><family>Noto Serif CJK SC</family></prefer>
      </alias>
      <alias>
        <family>SimSun-ExtB</family>
        <prefer><family>Noto Serif CJK SC</family></prefer>
      </alias>
      <alias>
        <family>NSimSun</family>
        <prefer><family>Noto Serif CJK SC</family></prefer>
      </alias>
      <alias>
        <family>DengXian</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>FangSong</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>KaiTi</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>

      <!-- Noto Sans CJK SC 是可变字体(VF)，部分 Electron 版不兼容 → 回退到 WenQuanYi -->
      <alias>
        <family>Noto Sans CJK SC</family>
        <prefer>
          <family>WenQuanYi Micro Hei</family>
          <family>Noto Sans CJK SC</family>
        </prefer>
      </alias>

      <!-- macOS 字体别名（CSS font-family 常见） -->
      <alias>
        <family>-apple-system</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>BlinkMacSystemFont</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>PingFang SC</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>PingFang HK</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>PingFang TC</family>
        <prefer><family>WenQuanYi Micro Hei</family></prefer>
      </alias>
      <alias>
        <family>Helvetica Neue</family>
        <prefer><family>Noto Sans</family></prefer>
      </alias>

      <!-- 其他 Windows 西文字体 → Noto Sans -->
      <alias>
        <family>Segoe UI</family>
        <prefer><family>Noto Sans</family></prefer>
      </alias>
      <alias>
        <family>Microsoft Sans Serif</family>
        <prefer><family>Noto Sans</family></prefer>
      </alias>
      <alias>
        <family>Tahoma</family>
        <prefer><family>Noto Sans</family></prefer>
      </alias>

      <!-- WPS 缺失的专有符号字体 → 已有字体别名 -->
      <alias>
        <family>Wingdings</family>
        <prefer><family>DejaVu Sans</family></prefer>
      </alias>
      <alias>
        <family>MT Extra</family>
        <prefer><family>DejaVu Sans</family></prefer>
      </alias>
      <alias>
        <family>Symbol</family>
        <prefer><family>Symbola</family></prefer>
      </alias>
    </fontconfig>
  '';

  # 字体配置：WenQuanYi Micro Hei 优先（非 VF，Electron 兼容性好）
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "WenQuanYi Micro Hei" "Noto Sans CJK SC" "Noto Sans" ];
    serif = [ "Noto Serif CJK SC" "Noto Serif" ];
    monospace = [ "FiraCode Nerd Font" "Noto Sans Mono CJK SC" ];
    emoji = [ "Noto Color Emoji" ];
  };
}
