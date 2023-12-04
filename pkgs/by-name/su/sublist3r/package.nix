{ lib
, fetchFromGitHub
# ,
}:
{
  installPhase = ''
    runHook preInstall
    install -Dm444 names.txt $out/share/wordlists/sublist3r_names.txt
    runHook postInstall
  '';
}
