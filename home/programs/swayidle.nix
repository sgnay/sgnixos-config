{ pkgs, ... }:
let
  # dms ipc 内部 exec("qs", ...) 依赖 quickshell CLI，必须把其 bin 目录加入 PATH，
  # 否则在 swayidle 服务（PATH 仅含 bash）中会报 "qs: executable file not found"
  lockCmd = "PATH=${pkgs.quickshell}/bin:${pkgs.dms-shell}/bin:$PATH ${pkgs.dms-shell}/bin/dms ipc call lock lock";
in
{
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 180;
        command = lockCmd;
      }
      {
        timeout = 300;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events.before-sleep = lockCmd;
  };
}

