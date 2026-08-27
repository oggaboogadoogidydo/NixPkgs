{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
  root = ./pkgs;

  # Recursively scan for .nix files
  # Returns a list of { segments = ["path" "to" "package"], path = "/path/to/package.nix" }
  collect = dir: prefix:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;

      # Process a single .nix file
      processFile = name:
        let
          stem = lib.removeSuffix ".nix" name;
          # If the file is default.nix, use the parent directory name as the attribute
          segments = if stem == "default" then prefix else prefix ++ [stem];
        in
        # Ignore a root-level default.nix to avoid shadowing the channel's entry point
        if stem == "default" && prefix == [] then null
        else { inherit segments; path = dir + "/${name}"; };

      fileResults = builtins.map processFile (builtins.filter (n: lib.hasSuffix ".nix" n) names);

      # Process subdirectories
      subdirs = builtins.filter (n: entries.${n} == "directory") names;
      subResults = builtins.concatMap (sub: collect (dir + "/${sub}") (prefix ++ [sub])) subdirs;

      allResults = builtins.filter (x: x != null) (fileResults ++ subResults);
    in
    allResults;

  # Collect all package definitions
  collected = collect root [];

  # Build a nested attribute set
  pkgSet = builtins.foldl' (acc: item:
    let
      set = lib.setAttrByPath item.segments (pkgs.callPackage item.path {});
    in
    lib.recursiveUpdate acc set
  ) {} collected;

in
pkgSet
