{
  lib,
  pkgs,
  mkFormat,
}:
let
  inherit (pkgs) buildPackages callPackage;

  hocon-generator = buildPackages.rustPlatform.buildRustPackage {
    name = "hocon-generator";
    version = "0.1.0";
    src = ./src;

    passthru.updateScript = ./update.sh;

    cargoLock.lockFile = ./src/Cargo.lock;
  };

  hocon-validator =
    pkgs.writers.writePython3Bin "hocon-validator"
      {
        libraries = [ pkgs.python3Packages.pyhocon ];
      }
      ''
        from sys import argv
        from pyhocon import ConfigFactory

        if not len(argv) == 2:
            print("USAGE: hocon-validator <file>")

        ConfigFactory.parse_file(argv[1])
      '';
in

mkFormat (formatConfig: {
  name = "hocon";

  features = {
    enableSubstitution = true;
    enableIncluded = true;
    enableAppend = true;
  };

  type =
    let
      type' =
        with lib.types;
        let
          atomType = nullOr (oneOf [
            bool
            float
            int
            path
            str
          ]);

          includeType = addCheck attrs (x: (x._type or null) == "include");
          substitutionType = addCheck attrs (x: (x._type or null) == "substitution");
          appendType = addCheck attrs (x: (x._type or null) == "append");

          disabledTypeTags =
            lib.optional (!formatConfig.features.enableIncluded) "include"
            ++ lib.optional (!formatConfig.eatures.enableSubstitution) "substitution"
            ++ lib.optional (!formatConfig.eatures.enableAppend) "append";

          baseType = oneOf (
            [
              atomType
              (addCheck (listOf atomType) (lib.all atomType.check))
            ]
            ++ lib.optional formatConfig.features.enableIncluded (
              addCheck (listOf includeType) (lib.all includeType.check)
            )
            ++ lib.optional formatConfig.features.enableSubstitution substitutionType
            ++ lib.optional formatConfig.features.enableAppend appendType
            ++ [ (attrsOf type') ]
          );
        in
        baseType
        // {
          description = "HOCON value";
          check = x: baseType.check x && !(lib.isAttrs x && lib.elem (x._type or null) disabledTypeTags);
        };
    in
    type';

  lib = {
    mkInclude =
      value:
      lib.throwIf (!formatConfig.features.enableIncluded)
        "hocon.lib.mkInclude is disabled via `features.enableIncluded`"
        (
          let
            includeStatement =
              if lib.isAttrs value && !(lib.isDerivation value) then
                {
                  required = false;
                  type = null;
                  _type = "include";
                }
                // value
              else
                {
                  value = toString value;
                  required = false;
                  type = null;
                  _type = "include";
                };
          in
          assert lib.assertMsg
            (lib.elem includeStatement.type [
              "file"
              "url"
              "classpath"
              null
            ])
            ''
              Type of HOCON mkInclude is not of type 'file', 'url' or 'classpath':
              ${(lib.generators.toPretty { }) includeStatement}
            '';
          includeStatement
        );

    mkAppend =
      value:
      lib.throwIf (!formatConfig.features.enableAppend)
        "hocon.lib.mkAppend is disabled via `features.enableAppend`"
        {
          inherit value;
          _type = "append";
        };

    mkSubstitution =
      value:
      lib.throwIf (!formatConfig.features.enableSubstitution)
        "hocon.lib.mkSubstitution is disabled via `features.enableSubstitution`"
        (
          if lib.isString value then
            {
              inherit value;
              optional = false;
              _type = "substitution";
            }
          else
            assert lib.assertMsg (lib.isAttrs value) ''
              Value of invalid type provided to `hocon.lib.mkSubstitution`: ${lib.typeOf value}
            '';
            assert lib.assertMsg (value ? "value") ''
              Argument to `hocon.lib.mkSubstitution` is missing a `value`:
              ${builtins.toJSON value}
            '';
            {
              value = value.value;
              optional = value.optional or false;
              _type = "substitution";
            }
        );
  };

  nativeBuildInputs = [
    pkgs.jq
    hocon-generator
  ];
  buildPhase = ''
    jq .value "$NIX_ATTRS_JSON_FILE" | hocon-generator > output
  '';

  nativeCheckInputs = [
    hocon-validator
  ];
  formatCheckPhase = ''
    hocon-validator output
  '';
})
