{ lib
, pkgs
}:
let
  inherit (pkgs) buildPackages callPackage;
  # Implementation notes:
  #   KDL spec: https://github.com/kdl-org/kdl/blob/main/SPEC.md

  # TODO:
  # kdl-generator = buildPackages.rustPlatform.buildRustPackage {
  #   name = "kdl-generator";
  #   version = "0.1.0";
  #   src = ./src;

  #   passthru.updateScript = ./update.sh;

  #   cargoLock.lockFile = ./src/Cargo.lock;
  # };

  # TODO:
  # kdl-validator = buildPackages.runCommandCC "kdl-validator"
  #   {
  #     buildInputs = with buildPackages; [ libconfig ];
  #   }
  #   ''
  #     mkdir -p "$out/bin"
  #     $CC -lconfig -x c - -o "$out/bin/libconfig-validator" ${./validator.c}
  #   '';
in
{
  # format = { generator ? kdl-generator, validator ? kdl-validator }: {
  format = {  }: {
    # inherit generator;

    type = with lib.types;
      let
        simpleValue = nullOr (oneOf [ int float bool str ]);
        # nodeType =
        #   -> type (nullOr str)
        #   -> name (str)
        #   -> arguments (listOf simpleValue) # These are ordered
        #   -> properties (attrsOf simpleValue) # These are not ordered
        #   -> children (coercedTo (attrsOf nodeType) -> (listOf nodeType)) # These are ordered
        #        the coercion is just a shorthand, for ease of use

        valueType = (oneOf [
          bool
          int
          float
          str
          path
          (attrsOf valueType)
          (listOf valueType)
        ]) // {
          description = "libconfig value";
        };
      in
      attrsOf valueType;

    lib = {
      #mkTyped
      #mkRawString
      # mkHex = value: {
      #   _type = "hex";
      #   inherit value;
      # };
      # mkOctal = value: {
      #   _type = "octal";
      #   inherit value;
      # };
      # mkFloat = value: {
      #   _type = "float";
      #   inherit value;
      # };
      # mkArray = value: {
      #   _type = "array";
      #   inherit value;
      # };
      # mkList = value: {
      #   _type = "list";
      #   inherit value;
      # };
    };

    generate = name: value:
      callPackage
        ({
          stdenvNoCC
        , libconfig-generator
        , libconfig-validator
        , writeText
        }: stdenvNoCC.mkDerivation rec {
          inherit name;

          dontUnpack = true;

          json = builtins.toJSON value;
          passAsFile = [ "json" ];

          strictDeps = true;
          nativeBuildInputs = [ libconfig-generator ];
          buildPhase = ''
            runHook preBuild
            libconfig-generator < $jsonPath > output.cfg
            runHook postBuild
          '';

          doCheck = true;
          nativeCheckInputs = [ libconfig-validator ];
          checkPhase = ''
            runHook preCheck
            libconfig-validator output.cfg
            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall
            mv output.cfg $out
            runHook postInstall
          '';

          passthru.json = writeText "${name}.json" json;
        })
        {
          libconfig-generator = generator;
          libconfig-validator = validator;
        };
  };
}
