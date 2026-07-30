# home/programs/rime.nix — Rime 输入法配置（雾凇拼音 rime-ice）
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) homeDirectory;
  rimeDir = "${homeDirectory}/.local/share/fcitx5/rime";
  rimeIcePath = "${pkgs.rime-ice}/share/rime-data";
in {
  home.packages = with pkgs; [
    rime-ice
  ];

  # rime-ice 数据文件通过 home.activation 创建符号链接到用户 rime 目录
  home.activation.setupRimeIce = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # 创建 rime 用户目录
    mkdir -p "${rimeDir}"

    # 创建 rime-ice 符号链接（如果不存在）
    if [ ! -L "${rimeDir}/rime_ice.schema.yaml" ]; then
      for f in "${rimeIcePath}"/*; do
        name="$(basename "$f")"
        # 不覆盖已有的常规文件（如 default.custom.yaml）
        if [ -f "${rimeDir}/$name" ] && [ ! -L "${rimeDir}/$name" ]; then
          continue
        fi
        ln -sf "$f" "${rimeDir}/$name"
      done
      # 符号链接子目录
      for dir in cn_dicts en_dicts lua opencc build; do
        if [ -d "${rimeIcePath}/$dir" ] && [ ! -e "${rimeDir}/$dir" ]; then
          ln -sf "${rimeIcePath}/$dir" "${rimeDir}/$dir"
        fi
      done
    fi
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
  '';
}
