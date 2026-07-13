{
  lib,
  config,
  ...
}: let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in {
  mkDotfileLinks = dirName: files:
    lib.listToAttrs (map (file: {
        name = "${dirName}/${file}";
        value = {source = mkLink "/etc/nixos/dotfiles/${dirName}/${file}";};
      })
      files);
}
