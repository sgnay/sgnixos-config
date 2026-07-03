{ config, pkgs, ... }:
{
  # PipeWire 音频服务（Wayland 标配）
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true;
    jack.enable = true;
  };

  # 蓝牙音频（可选，按需启用）
  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;
}
