# home/programs/rime.nix — Rime 输入法配置（雾凇拼音 rime-ice）
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) homeDirectory;
  rimeDir = "${homeDirectory}/.local/share/fcitx5/rime";
  rimeDataPath = "${pkgs.rime-data}/share/rime-data";
  rimeIcePath = "${pkgs.rime-ice}/share/rime-data";
in {
  # rime 基础数据及 rime-ice 词库通过 home.activation 创建符号链接到用户 rime 目录
  home.activation.setupRimeIce = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # 创建 rime 用户目录
    mkdir -p "${rimeDir}"

    # 确保 build 目录是真正的可写目录，不能是 Nix Store 的只读符号链接
    if [ -L "${rimeDir}/build" ]; then
      rm -f "${rimeDir}/build"
    fi
    mkdir -p "${rimeDir}/build"

    # 1. 符号链接 rime-data 基础数据文件（如 default.yaml, punctuation.yaml 等）
    for f in "${rimeDataPath}"/*; do
      name="$(basename "$f")"
      if [ "$name" = "build" ]; then continue; fi
      if [ -f "${rimeDir}/$name" ] && [ ! -L "${rimeDir}/$name" ]; then
        continue
      fi
      ln -sfn "$f" "${rimeDir}/$name"
    done

    # 2. 符号链接 rime-ice 方案文件与词库
    for f in "${rimeIcePath}"/*; do
      name="$(basename "$f")"
      if [ "$name" = "build" ]; then continue; fi
      if [ -f "${rimeDir}/$name" ] && [ ! -L "${rimeDir}/$name" ]; then
        continue
      fi
      ln -sfn "$f" "${rimeDir}/$name"
    done

    # 3. 符号链接子目录（如 cn_dicts, en_dicts, lua, opencc）
    for dir in cn_dicts en_dicts lua opencc; do
      if [ -L "${rimeDir}/$dir" ]; then
        rm -f "${rimeDir}/$dir"
      fi
      if [ -d "${rimeIcePath}/$dir" ] && [ ! -e "${rimeDir}/$dir" ]; then
        ln -sfn "${rimeIcePath}/$dir" "${rimeDir}/$dir"
      elif [ -d "${rimeDataPath}/$dir" ] && [ ! -e "${rimeDir}/$dir" ]; then
        ln -sfn "${rimeDataPath}/$dir" "${rimeDir}/$dir"
      fi
    done
  '';

  # Rime 配置文件（直接写入，使 rime 可检测改动触发部署）
  home.activation.setupRimeConfig = lib.hm.dag.entryAfter ["setupRimeIce"] ''
        # default.custom.yaml — 设定 rime-ice 为默认方案
        cat > "${rimeDir}/default.custom.yaml" << 'YAMLEOF'
    patch:
      # 继承 rime-ice 的完整配置
      __include: rime_ice_suggestion:/
      # 方案列表：全拼 + 英文混输
      schema_list:
        - schema: rime_ice
        - schema: melt_eng
    YAMLEOF

        # rime_ice.custom.yaml — rime-ice 个性化调整
        cat > "${rimeDir}/rime_ice.custom.yaml" << 'YAMLEOF'
    patch:
      # 初始状态为简体中文
      switches:
        - name: ascii_mode
          reset: 0
          states: ["中文", "西文"]
        - name: full_shape
          states: ["半角", "全角"]
        - name: simplification
          reset: 1
          states: ["漢字", "汉字"]
        - name: ascii_punct
          states: ["。，", "．，"]
    YAMLEOF

        # fcitx5 配置文件（确保 rime 加入活动输入法列表）
        fcitxProfile="${homeDirectory}/.config/fcitx5/profile"
        mkdir -p "$(dirname "$fcitxProfile")"
        if [ ! -f "$fcitxProfile" ] || ! grep -q "Name=rime" "$fcitxProfile"; then
          cat > "$fcitxProfile" << 'PROFILEEOF'
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=rime

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=rime
    Layout=

    [GroupOrder]
    0=Default
    PROFILEEOF
        fi
  '';
}
