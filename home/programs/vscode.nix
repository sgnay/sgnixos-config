{pkgs, ...}: {
  # VSCode 用户配置
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    # 关闭微软遥测
    profiles.default.userSettings = {
      # VSCode 1.68+ 统一的遥测级别控制
      "telemetry.telemetryLevel" = "off";
      # 旧版兼容（部分扩展读取）
      "telemetry.enableCrashReporter" = false;
      "telemetry.enableTelemetry" = false;

      # 关闭自动更新（Nix 包管理更新）
      "extensions.autoUpdate" = false;
      "update.mode" = "none";

      # 常用编辑器优化
      "editor.fontFamily" = "'FiraCode Nerd Font', 'Fira Code', 'Droid Sans Mono', 'monospace'";
      "editor.fontSize" = 14;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = false;
      "workbench.startupEditor" = "none";
      "workbench.colorTheme" = "Default Dark Modern";

      # 终端
      "terminal.integrated.fontFamily" = "'FiraCode Nerd Font', 'Fira Code', monospace";
      "terminal.integrated.fontSize" = 13;
    };

    # 默认扩展
    profiles.default.extensions = with pkgs.vscode-extensions; [
      # 语言支持
      ms-python.python
      ms-vscode.cpptools
      rust-lang.rust-analyzer
      golang.go
      redhat.java

      # 工具
      github.copilot
      github.copilot-chat
      ms-vscode.makefile-tools
      tamasfe.even-better-toml
      yzhang.markdown-all-in-one

      # 主题
      catppuccin.catppuccin-vsc
    ];
  };
}
