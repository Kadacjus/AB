{ pkgs, lib, ... }:
let
  forAllSystems = lib.genAttrs lib.systems.flakeExposed;

  models = {
    # opt-350 = {
    #   # from `pkgs`, not `builtins`, may not matter?
    #   url = "https://huggingface.co/facebook/opt-350m";
    #   rev = "08ab08cc4b72ff5593870b5d527cf4230323703c";
    #   hash = "sha256-tqPLcxtZ6WSNzFIVxUZ52LnXYFijDp6KzA6WMRVnMJM=";
    # };
    Stable-diffusion = {
      # from `pkgs`, not `builtins`, may not matter?
      file = "v1-5-pruned-emaonly.safetensors";
      url = "https://huggingface.co/sd-legacy/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors";
      hash = "sha256-bOAWFomzhTrKoDd57JPq/nWgL0ztZZvuA/UHl4Bvovo=";
    };
  };
  getModels = lib.attrsets.foldlAttrs (
    acc: name: value:
    let
      outDir = "$out/${name}";
      model = pkgs.fetchurl {
        inherit (value)
          url
          hash
          ;
      };
    in
    acc + "mkdir -p ${outDir} && cp -r ${model} ${outDir}/${value.file} \n"
  ) "" models;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "models";
  version = "1.0";
  dontUnpack = true;
  # Empty derivation, nothing to build
  installPhase = ''
    ${getModels}
  '';
  passthru = lib.attrsets.mapAttrs (
    name: value:

    pkgs.fetchurl {
      inherit (value)
        url
        hash
        ;
    }

  ) models;

}
