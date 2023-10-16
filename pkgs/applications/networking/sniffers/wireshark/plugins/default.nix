{ pkgs }:
let
  inherit (pkgs) callPackage;
in
{
  ffxiv-packet-dissector = callPackage ./ffxiv-packet-dissector { };
  h264extractor = callPackage ./h264extractor { };
  packet-simplemessage = callPackage ./packet-simplemessage { };
}
