{ lib, pkgs }:
let
  inherit (lib)
    mapAttrs
    optionalAttrs
    warn
    ;

  inherit (lib.types)
    attrsOf
    bool
    coercedTo
    either
    float
    int
    listOf
    luaInline
    mkOptionType
    nonEmptyListOf
    nullOr
    oneOf
    path
    str
    ;

  # Attributes added accidentally in https://github.com/NixOS/nixpkgs/pull/335232 (2024-08-18)
  # Deprecated in https://github.com/NixOS/nixpkgs/pull/415666 (2025-06)
  allowAliases = pkgs.config.allowAliases or false;
  aliasWarning = name: warn "`formats.${name}` is deprecated; use `lib.types.${name}` instead.";
  aliases = mapAttrs aliasWarning {
    inherit
      attrsOf
      bool
      coercedTo
      either
      float
      int
      listOf
      luaInline
      mkOptionType
      nonEmptyListOf
      nullOr
      oneOf
      path
      str
      ;
  };

  json2x = pkgs.buildPackages.callPackage ./formats/json2x/package.nix { };

  # `mkFormat` is the main building block for creating formats in pkgs-lib.
  # It ensures that the formats follow a canonical set of inputs and outputs,
  # and handles a lot of the common machinery for preprocessing and validation.
  #
  # You can either invoke this with an attrset of arguments, or as a function of
  # the arguments provided by the instantiator of the format.
  mkFormat = mkFormatArgsOrFn: {
    format =
      formatConfig:
      let
        mkFormatArgsDefaults = {
          # A lowercased unique name for the format.
          name = null;

          # The type of the format. Will commonly be passed as the `freeformType` of
          # NixOS modules.
          #
          # Please note that `pkgs` may not always be available for use due to the split
          # options doc build introduced in fc614c37c653, so lazy evaluation of only the
          # 'type' field is required.
          type = null;

          # The apply argument lets you apply a function to transform the final value
          # after filtering for empty values.
          apply = null;

          # This option allows you to configure the `stdenv` used for `mkDerivation`
          # when generating the resulting file.
          stdenv = pkgs.stdenvNoCC;

          # With `filter*ByDefault` you can control the default value of the according
          # filter* options in the format configuration. This is particularly useful
          # when defining formats that do not support certain types of empty values.
          filterNullsByDefault = false;
          filterEmptyListsByDefault = false;
          filterEmptyAttrsByDefault = false;

          # This phase is meant for syntax checks and linting of the format builder output.
          # The consumer of the format might choose to toggle this off.
          formatCheckPhase = "";

          # This attrset contains functions and other useful nix expressions that are
          # specifically useful when working with values of this format. If the format
          # is sufficiently advanced, you might want to provide a `mkRaw` escape hatch
          # here, which you will have to handle in the generator.
          lib = { };

          # This attrset contains subtypes of the format that downstream users might
          # want to use for typechecking options in NixOS modules. If the format can be
          # arbitrarily deeply nested, you should include the type of the leaf nodes
          # (sometimes named atoms) here.
          types = { };

          # This attrset lets you declare feature flags for the format, that might shape
          # how the format is validated and generated. This is useful when the format has
          # plugins, extensions or variants that only some software support.
          #
          # This attrset should only consist of boolean values with descriptive names.
          features = { };
        };

        mkFormatArgsWithDefaults =
          mkFormatArgsDefaults
          // (
            if builtins.isFunction mkFormatArgsOrFn then
              mkFormatArgsOrFn formatConfigWithDefaults
            else
              mkFormatArgsOrFn
          );

        mkDerivationExtraArgs = removeAttrs mkFormatArgsWithDefaults (lib.attrNames mkFormatArgsDefaults);

        inherit (mkFormatArgsWithDefaults)
          name
          type
          apply
          stdenv
          buildPhase
          formatCheckPhase
          ;

        # This is the configuration provided by the user invoking the format instance.
        formatConfigWithDefaults = {
          # Whether to run the format-specific syntax and linting checks.
          doFormatCheck = true;

          # Whether to invoke eval-time `type.check` on the value during preprocessing.
          #
          # Note that this is typically useless when the value is provided from a NixOS
          # module, as the module system will have run this check already.
          doTypeCheck = false;

          # An optional application-specific check for the resulting file. This is useful
          # for NixOS modules where the software provides a tool for static checking of
          # the configuration, which contains application specific rules (as opposed to
          # just checking the syntax of the format).
          customCheckPhase = null;

          # Whether to run the check phases as part of building the file.
          #
          # The generated derivation also comes with a passthru derivation only meant
          # for running the checks. In the future, it would be preferrable if we could move
          # all the checks in the NixOS module system to `system.checks`, but for now
          # this is enabled by default to maintain backwards compatibility.
          inlineChecks = true;

          # Optionally specify a path within the derivation where you would like
          # the generated file to end up.
          path = null;

          # Whether to recursively filter `null` values during preprocessing.
          filterNulls = mkFormatArgsWithDefaults.filterNullsByDefault;

          # Whether to recursively filter empty lists during preprocessing.
          filterEmptyLists = mkFormatArgsWithDefaults.filterEmptyListsByDefault;

          # Whether to recursively filter empty attrs during preprocessing.
          filterEmptyAttrs = mkFormatArgsWithDefaults.filterEmptyAttrsByDefault;

          # Which features to enable or disable for this instance of the format.
          features = mkFormatArgsWithDefaults.features;

          # Whether to extract out all nested `{ _secret = "<path>" }` attributes,
          # and replace them with a marker value. The list of marker values
          # can be retrieved through `passthru.secrets` as well as `passthru.secretsJson`.
          enableSecretHandling = false;
        }
        // formatConfig;

        inherit (formatConfigWithDefaults)
          filterNulls
          filterEmptyLists
          filterEmptyAttrs
          doFormatCheck
          doTypeCheck
          customCheckPhase
          inlineChecks
          enableSecretHandling
          path
          ;

        deepFilter =
          {
            filterNulls,
            filterEmptyLists,
            filterEmptyAttrs,
          }:
          let
            isPrunable =
              v: (filterNulls && v == null) || (filterEmptyLists && v == [ ]) || (filterEmptyAttrs && v == { });

            deepFilter' =
              value:
              if lib.isDerivation value then
                value
              else if lib.isAttrs value then
                lib.filterAttrs (_: v: !isPrunable v) (mapAttrs (_: deepFilter') value)
              else if lib.isList value then
                builtins.filter (v: !isPrunable v) (map deepFilter' value)
              else
                value;
          in
          deepFilter';

        extractSecrets =
          value:
          let
            isSecretMarker = v: lib.isAttrs v && (lib.attrNames v) == [ "_secret" ] && lib.isString v._secret;

            mkMarker =
              keyPath:
              "@secret-"
              + builtins.hashString "sha256" (
                lib.concatMapStringsSep "/" (key: if lib.isInt key then toString key else key) keyPath
              )
              + "@";

            mergeSecrets = results: lib.foldl' (acc: r: acc // r.secrets) { } results;

            extractSecrets' =
              keyPath: value:
              if isSecretMarker value then
                let
                  marker = mkMarker keyPath;
                in
                {
                  value = marker;
                  secrets.${marker} = value._secret;
                }
              else if lib.isDerivation value then
                {
                  inherit value;
                  secrets = { };
                }
              else if lib.isAttrs value then
                let
                  results = mapAttrs (name: extractSecrets' (keyPath ++ [ name ])) value;
                in
                {
                  value = mapAttrs (_: r: r.value) results;
                  secrets = mergeSecrets (lib.attrValues results);
                }
              else if lib.isList value then
                let
                  results = lib.imap0 (i: extractSecrets' (keyPath ++ [ i ])) value;
                in
                {
                  value = map (r: r.value) results;
                  secrets = mergeSecrets results;
                }
              else
                {
                  inherit value;
                  secrets = { };
                };
          in
          extractSecrets' [ ] value;

        preprocess =
          value:
          lib.pipe value (
            [ ]
            ++ lib.optionals doTypeCheck [
              (
                value:
                lib.throwIfNot (type.check value)
                  (builtins.trace value "definition does not pass the type's check function")
                  value
              )
            ]
            ++ lib.optionals (filterNulls || filterEmptyLists || filterEmptyAttrs) [
              (deepFilter { inherit filterNulls filterEmptyLists filterEmptyAttrs; })
            ]
            ++ lib.optionals (apply != null) [ apply ]
          );
      in
      {
        inherit name type;

        lib = mkFormatArgsWithDefaults.lib // {
          inherit (mkFormatArgsWithDefaults) types;
        };

        inherit preprocess;

        generate =
          name: value:
          let
            preprocessed' = preprocess value;
            preprocessed =
              if enableSecretHandling then
                extractSecrets preprocessed'
              else
                {
                  value = preprocessed';
                  secrets = { };
                };
          in
          stdenv.mkDerivation (
            mkDerivationExtraArgs
            // optionalAttrs doFormatCheck {
              formatCheckPhase = ''
                runHook preFormatCheckPhase
                ${formatCheckPhase}
                runHook postFormatCheckPhase
              '';
            }
            // optionalAttrs (customCheckPhase != null) {
              customCheckPhase = ''
                runHook preCustomCheckPhase
                ${customCheckPhase}
                runHook postCustomCheckPhase
              '';
            }
            // {
              inherit name;
              value = preprocessed.value;

              strictDeps = true;
              __structuredAttrs = true;
              preferLocalBuild = true;

              phases = [
                "buildPhase"
              ]
              ++ lib.optionals inlineChecks (
                lib.optional doFormatCheck "formatCheckPhase"
                ++ lib.optional (customCheckPhase != null) "customCheckPhase"
              )
              ++ [
                "installPhase"
              ];

              buildPhase = ''
                runHook preBuild
                ${buildPhase}
                runHook postBuild
              '';

              doCheck = inlineChecks && (doFormatCheck || customCheckPhase != null);

              installPhase = ''
                runHook preInstall
                ${
                  if path != null then ''install -Dm444 output "$out"/${path}'' else ''install -Dm444 output "$out"''
                }
                runHook postInstall
              '';

              passthru = {
                checkDrv = stdenv.mkDerivation (
                  mkDerivationExtraArgs
                  // optionalAttrs doFormatCheck {
                    formatCheckPhase = ''
                      runHook preFormatCheckPhase
                      ${formatCheckPhase}
                      runHook postFormatCheckPhase
                    '';
                  }
                  // optionalAttrs (customCheckPhase != null) {
                    customCheckPhase = ''
                      runHook preCustomCheckPhase
                      ${customCheckPhase}
                      runHook postCustomCheckPhase
                    '';
                  }
                  // {
                    name = "check-${name}";
                    value = preprocessed.value;

                    strictDeps = true;
                    __structuredAttrs = true;

                    phases = [
                      "buildPhase"
                    ]
                    ++ lib.optional doFormatCheck "formatCheckPhase"
                    ++ lib.optional (customCheckPhase != null) "customCheckPhase"
                    ++ [
                      "installPhase"
                    ];

                    buildPhase = ''
                      runHook preBuild
                      ${buildPhase}
                      runHook postBuild
                    '';

                    doCheck = doFormatCheck || customCheckPhase != null;

                    installPhase = ''
                      runHook preInstall
                      touch "$out"
                      runHook postInstall
                    '';
                  }
                );

                formatConfig = formatConfigWithDefaults;

                secrets = preprocessed.secrets;
                secretsJson = builtins.toJSON preprocessed.secrets;
              };
            }
          );
      };
  };
in
optionalAttrs allowAliases aliases
// rec {

  /*
    Every following entry represents a format for program configuration files
    used for `settings`-style options (see https://github.com/NixOS/rfcs/pull/42).
    Each entry should look as follows:

      <format> = <parameters>: {
        #        ^^ Parameters for controlling the format

        # The module system type most suitable for representing such a format
        # The description needs to be overwritten for recursive types
        type = ...;

        # Utility functions for convenience, or special interactions with the
        # format (optional)
        lib = {
          exampleFunction = ...
          # Types specific to the format (optional)
          types = { ... };
          ...
        };

        # generate :: Name -> Value -> Path
        # A function for generating a file with a value of such a type
        generate = ...;

      });

    Please note that `pkgs` may not always be available for use due to the split
    options doc build introduced in fc614c37c653, so lazy evaluation of only the
    'type' field is required.
  */

  cdn = (import ./formats/cdn/default.nix { inherit lib pkgs; }).format;

  configobj = (import ./formats/configobj/default.nix { inherit lib pkgs; }).format;

  elixirConf = (import ./formats/elixir-conf/default.nix { inherit lib pkgs; }).format;

  gitIni = (import ./formats/git-ini/default.nix { inherit lib pkgs; }).format;

  hcl1 = (import ./formats/hcl1/default.nix { inherit lib pkgs json; }).format;

  hocon = (import ./formats/hocon/default.nix { inherit lib pkgs mkFormat; }).format;

  ini = (import ./formats/ini/default.nix { inherit lib pkgs; }).format;

  iniWithGlobalSection =
    (import ./formats/ini-with-global-section/default.nix { inherit lib pkgs; }).format;

  javaProperties = (import ./formats/java-properties/default.nix { inherit lib pkgs; }).format;

  json = (import ./formats/json/default.nix { inherit lib pkgs mkFormat; }).format;

  keyValue = (import ./formats/key-value/default.nix { inherit lib pkgs; }).format;

  libconfig = (import ./formats/libconfig/default.nix { inherit lib pkgs; }).format;

  lua = (import ./formats/lua/default.nix { inherit lib pkgs; }).format;

  nixConf = (import ./formats/nix-conf/default.nix { inherit lib pkgs; }).format;

  php = (import ./formats/php/default.nix { inherit lib pkgs; }).format;

  plist = (import ./formats/plist/default.nix { inherit lib pkgs; }).format;

  pythonVars = (import ./formats/python-vars/default.nix { inherit lib pkgs; }).format;

  systemd = (import ./formats/systemd/default.nix { inherit lib pkgs ini; }).format;

  toml = (import ./formats/toml/default.nix { inherit lib pkgs json2x; }).format;

  xml = (import ./formats/xml/default.nix { inherit lib pkgs; }).format;

  yaml = yaml_1_1;

  yaml_1_1 = (import ./formats/yaml-1-1/default.nix { inherit lib pkgs; }).format;

  yaml_1_2 = (import ./formats/yaml-1-2/default.nix { inherit lib pkgs; }).format;
}
