{ pkgs }:
let
  inherit (pkgs) callPackage;
in
{
  h264extractor = callPackage ./h264extractor { };
}
