{
  lib,
  config,
  ...
}:
let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in
{
  mkDotfileLinks =
    dirName: files:
    lib.listToAttrs (
      map (file: {
        name = if dirName == "" then file else "${dirName}/${file}";
        value = {
          source = mkLink "/etc/nixos/dotfiles/${if dirName == "" then file else "${dirName}/${file}"}";
        };
      }) files
    );
}
