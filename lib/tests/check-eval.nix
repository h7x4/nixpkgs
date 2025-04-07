# Throws an error if any of our lib tests fail.

let
  tests = [
    "misc"
    "systems"
  ];
  all = builtins.concatMap (f: import (./. + "/${f}.nix")) tests;
in
if all == [ ] then null else throw (builtins.toJSON all)
