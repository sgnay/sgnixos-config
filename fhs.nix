# fhs.nix — 通用 FHS (Filesystem Hierarchy Standard) 环境配置
# 使用说明：
# 1. 运行 `nix-shell /etc/nixos/fhs.nix` 或在当前目录运行 `nix-shell fhs.nix`
# 2. 进入环境后，所有的动态链接库路径（/lib, /usr/lib）均符合传统 Linux FHS 规范，
#    可直接运行未经 Nix 补丁 (patchelf) 的第三方二进制可执行文件、SDK 或闭源程序。
{pkgs ? import <nixpkgs> {}}:
(pkgs.buildFHSEnv {
  name = "fhs-env";

  # 需要映射到 FHS 环境 (/lib, /usr/lib, /bin 等) 中的软件包和库
  targetPkgs = pkgs: (with pkgs; [
    # 基础 C/C++ 运行时与标准库
    glibc
    gcc
    stdenv.cc.cc.lib # 提供 libstdc++.so.6 及 libgomp.so.1
    gnumake
    cmake
    pkg-config

    # 通用系统库
    zlib
    openssl
    curl
    wget
    glib
    dbus
    icu
    libffi
    ncurses
    readline

    # 图形与渲染 (X11 / OpenGL / 字体)
    libGL
    fontconfig
    freetype
    libX11
    libXext
    libXrender
    libXi
    libXrandr
    libXcursor
    libXinerama
    libxcb
    libXfixes

    # 常用开发工具
    git
    file
    which
    unzip
    p7zip
    bash
    coreutils
  ]);

  # 如需兼容 32 位二进制文件，可以在此处包含 32 位依赖库
  multiPkgs = pkgs: (with pkgs; [
    zlib
  ]);

  # 允许在 host 的 /etc/nixos 路径下启动 fhs 环境：
  # 默认情况下 bwrap 会遮蔽 host 的 /etc（仅链接必要的系统文件），
  # 如果从 /etc/nixos 启动，bwrap --chdir $(pwd) 会报 Can't chdir to /etc/nixos。
  # 通过 extraBwrapArgs 显式挂载 /etc/nixos 目录即可解决。
  extraBwrapArgs = [
    "--bind-try"
    "/etc/nixos"
    "/etc/nixos"
  ];

  # 进入 FHS 环境前要设置的环境变量与初始化配置
  profile = ''
    export FHS_ENV_ACTIVE=1
    export LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH
    echo "=================================================="
    echo " 已成功进入 NixOS FHS 隔离环境 (fhs-env)"
    echo " 环境内包含标准的 /bin, /usr/bin, /lib, /usr/lib 结构"
    echo " 输入 exit 可退出当前 FHS 环境"
    echo "=================================================="
  '';

  # 默认启动的 Shell 界面
  runScript = "bash";
}).env
