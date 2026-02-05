{
  inputs,
  lib,
  self,
  ...
}:
let
  mkFormat =
    height: "bestvideo[height<=?${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best";
in
{
  perSystem =
    { pkgs, ... }:
    let
      source = (self.libCustom.nvFetcherSources pkgs).yt-dlp;
    in
    {
      packages.yt-dlp' = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.yt-dlp.overrideAttrs source;
        flags = {
          "--add-metadata" = true;
          "--format" = mkFormat 720;
          "--no-mtime" = true;
          "--output" = "%(title)s.%(ext)s";
          "--sponsorblock-mark" = "all";
          "--windows-filenames" = true;
          # youtube causing 403 errors
          # https://github.com/yt-dlp/yt-dlp/issues/15712#issuecomment-3808702603
          # PR: https://github.com/yt-dlp/yt-dlp/pull/15726
          "--extractor-args" = "youtube:player_client=default,-android_sdkless";
        };
      };
    };

  flake.nixosModules.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          yt-dlp = pkgs.custom.yt-dlp';
        })
      ];

      environment = {
        shellAliases = {
          yt = "yt-dlp";
          yt1080 = ''ytdl --format "${mkFormat 1080}"'';
          ytaudio = "ytdl --audio-format mp3 --extract-audio";
          ytsubonly = "ytdl --skip-download --write-subs";
          ytplaylist = "ytdl --output '%(playlist_index)d - %(title)s.%(ext)s'";
        };

        systemPackages = with pkgs; [
          yt-dlp # overlay-ed above
        ];
      };

      custom.programs.print-config = {
        yt-dlp = /* sh */ ''cat "${lib.getExe pkgs.yt-dlp}"'';
      };
    };
}
