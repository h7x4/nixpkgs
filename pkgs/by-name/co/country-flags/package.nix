# { lib
# , stdenvNoCC
# , fetchFromGitHub
# }:
# stdenvNoCC.mkDerivation (finalAttrs: {
#   pname = "country-flags";
#   version = "unstable-2021-11-15";
#   src = fetchFromGitHub {
#     owner = "hampusborgos";
#     repo = "country-flags";
#     rev = "ba2cf4101bf029d2ada26da2f95121de74581a4d";
#     hash = "";
#   };

#   installPhase = ''
#     runHook preInstall


#     runHook postInstall
#   '';

#   meta = with lib; {

#   };
# })
