{ lib, ... }:
{
  options = {
    assertions = lib.mkOption {
      type = let
        assertionItemType = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              description = ''
                Whether to enable this assertion.

                This option is mostly useful for users, in order to forcefully disable assertions they believe to be
                erroneous while waiting for someone to fix the assertion upstream.
              '';
              type = lib.types.bool;
              default = true;
              example = false;
            };

            assertion = lib.mkOption {
              description = "Condition to be asserted. If this is `false`, the evaluation will throw the error";
              type = lib.types.bool;
              example = false;
            };

            message = lib.mkOption {
              description = "The contents of the error message that should be shown upon triggering a false assertion";
              type = lib.types.nonEmptyStr;
              example = "This is an example error message";
            };
          };
        };

        # This might be replaced when tagged submodules or similar are available,
        # see https://github.com/NixOS/nixpkgs/pull/254790
        checkedAssertionItemType = let
          check = x: x ? assertion && x ? message;
        in lib.types.addCheck assertionItemType check;

        nestedAssertionAttrsType = with lib.types; let
          nestedAssertionItemType = oneOf [
            checkedAssertionItemType
            (attrsOf nestedAssertionItemType)
          ];
        in nestedAssertionItemType // {
          description = "nested attrs of (${assertionItemType.description})";
        };

        # Backwards compatibility for assertions that are still written as attrs inside a list.
        # The attribute name will be set to the sha256 sum of the assertion message, e.g. `assertions.legacy."<sha256>" = { ... }`
        coercedAssertionAttrs = let
          coerce = xs: {
            legacy = lib.listToAttrs (map (assertion: lib.nameValuePair (builtins.hashString "sha256" assertion.message) assertion) xs);
          };
        in with lib.types; coercedTo (listOf (attrsOf unspecified)) coerce (submodule { freeformType = nestedAssertionAttrsType; });
      in coercedAssertionAttrs;
      internal = true;
      default = { };
      example = lib.literalExpression ''
        {
          programs.foo.dontUseSomeOption = {
            assertion = !config.programs.foo.settings.someOption;
            message = "You can't enable foo's someOption for some reason";
          };
          services.bar.mutuallyExclusiveWithFoo = {
            assertion = config.services.bar.enable -> !config.programs.foo.enable;
            message = "You can't use the 'foo' program if you're using the 'bar' service";
          };
        }
      '';
      description = ''
        This option allows modules to express conditions that must
        hold for the evaluation of the system configuration to
        succeed, along with associated error messages for the user.
      '';
    };

    warnings = lib.mkOption {
      type = let
        warningItemType = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              description = ''
                Whether to enable this warning.

                This option is mostly useful for users, in order to forcefully disable warnings they believe to be
                erroneous while waiting for someone to fix the condition upstream.
              '';
              type = lib.types.bool;
              default = true;
              example = false;
            };

            condition = lib.mkOption {
              description = "Condition that triggers the warning message. If this is `true`, the warning will be shown";
              type = lib.types.bool;
              example = true;
            };

            message = lib.mkOption {
              description = "The contents of the warning message that should be shown upon triggering the condition";
              type = lib.types.nonEmptyStr;
              example = "This is an example warning message";
            };
          };
        };

        # This might be replaced when tagged submodules or similar are available,
        # see https://github.com/NixOS/nixpkgs/pull/254790
        checkedWarningItemType = let
          check = x: x ? condition && x ? message;
        in lib.types.addCheck warningItemType check;

        nestedWarningAttrsType = with lib.types; let
          nestedWarningItemType = oneOf [
            checkedWarningItemType
            (attrsOf nestedWarningItemType)
          ];
        in nestedWarningItemType // {
          description = "nested attrs of (${warningItemType.description})";
        };

        # Backwards compatibility for warnings that are still written as strings inside a list.
        # The attribute name will be set to the sha256 sum of the warning message, e.g. `warnings."<sha256>" = { ... }`
        coercedWarningAttrs = let
          coerce = xs: {
            legacy = lib.listToAttrs (map (message: lib.nameValuePair (builtins.hashString "sha256" message) {
              inherit message;
              condition = true;
            }) xs);
          };
        in with lib.types; coercedTo (listOf str) coerce (submodule { freeformType = nestedWarningAttrsType; });
      in coercedWarningAttrs;
      internal = true;
      default = { };
      example = lib.literalExpression ''
        {
          services.foo.deprecationNotice = {
            condition = config.services.foo.enable;
            message = "The `foo' service is deprecated and will go away soon!";
          };
          services.bar.otherWarning = {
            condition = !config.services.bar.settings.importantOption;
            message = "You might want to enable services.bar.settings.importantOption, or everything is going to break";
          };
        }
      '';
      description = ''
        This option allows modules to show warnings to users during
        the evaluation of the system configuration.
      '';
    };
  };
  # impl of assertions is in <nixpkgs/nixos/modules/system/activation/top-level.nix>
}
