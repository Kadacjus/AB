{
  lib,
  pkgs,
  system,
  package-name,
  pythonSet,
  self,
  ...
}:
let
  venv = self.packages.${system}.venv;
in
pkgs.stdenv.mkDerivation rec {
  name = "${package-name}-static";
  inherit (pythonSet.${package-name}) src;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = with pkgs; [
    venv
    makeWrapper
    cacert
  ];
  buildInputs = with pkgs; [ git ];

  installPhase =
    let
      repoDir = "$out/";
      getDeps = lib.attrsets.foldlAttrs (
        acc: name: value:
        acc + "ln -s ${value} ${repoDir}/repositories/${name} \n"
      ) "" self.packages.${system}.deps.passthru;
      # getModels = lib.attrsets.foldlAttrs (
      #   acc: name: value:
      #   acc + "ln -s ${value} ${repoDir}/models/${name} \n"
      # ) "" self.packages.${system}.models.passthru;
      script = pkgs.writeShellScriptBin "${name}" ''
        ${venv}/bin/python launch.py --skip-prepare-environment --skip-install "$@"
      '';
    in
    ''
      mkdir -p ${repoDir}/repositories
      mkdir -p ${repoDir}/models/Stable-diffusion
      mkdir -p $out/bin
      cp -r $src/* ${repoDir}
      ${getDeps}

      cp ${lib.getExe script} $out/bin
    '';
  postFixup = ''
    wrapProgram $out/bin/${name} \
      --set PATH ${
        lib.makeBinPath [
          venv
          pkgs.coreutils
          pkgs.git
        ]
      }
  '';
}
