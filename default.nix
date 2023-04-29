let

  pkgs = import (builtins.fetchGit {
    name = "nixos-21.05";
    url = "https://github.com/nixos/nixpkgs/";
    ref = "refs/heads/nixos-21.05";
    rev = "a1007637cea374bd1bafd754cfd5388894c49129";
    }) {};

  site = pkgs.stdenv.mkDerivation rec {
    src = pkgs.lib.cleanSource ./.;
    name = "website";

    buildInputs = with pkgs; [
      imagemagick
      python38Packages.lektor
    ];

    installPhase = ''
        mkdir -p $out
        lektor build -O $out
    '';
  };

  scheduler = import (pkgs.fetchFromGitHub {
    owner = "section77";
    repo = "chaostreff-scheduler";
    rev = "3bd18314c0f5c8d4c8f4f11d30465c1db74120fc";
    sha256 = "sha256-9NW3Lp/oS026NAvhTid/CSG1SRjaZWARCwDfvmo6Hys=";
  });
  #scheduler = import ../chaostreff-scheduler ;

  schedule = pkgs.stdenv.mkDerivation rec {
    name = "schedule";
    src = ./.;
    buildInputs = [ scheduler pkgs.git ];
    installPhase = ''
      mkdir $out

      export HOME=$TEMP
      git config --global user.name "chaostreff-scheduler"
      git config --global user.email "chaostreff-scheduler@section77.de"

      chaostreff-scheduler --no-push -r $src -w $out -c 2
    '';
  };
in
if pkgs.lib.inNixShell then pkgs.mkShell {
  buildInputs = site.buildInputs;

  shellHook = ''
    lektor server -h 0.0.0.0 -p 5001
  '';
}
else {
  inherit site schedule;
}

