{ pkgs, lib, ... }:
let
  forAllSystems = lib.genAttrs lib.systems.flakeExposed;

  deps = {
    stable-diffusion-webui-assets = {
      owner = "AUTOMATIC1111";
      repo = "stable-diffusion-webui-assets";
      rev = "6f7db241d2f8ba7457bac5ca9753331f0c266917";
      hash = "sha256-gos24/VHz+Es834ZfMVdu3L9m04CR0cLi54bgTlWLJk=";
    };
    stable-diffusion-stability-ai = {
      owner = "Stability-AI";
      repo = "stablediffusion";
      rev = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf";
      hash = "sha256-yEtrz/JTq53JDI4NZI26KsD8LAgiViwiNaB2i1CBs/I=";
    };
    generative-models = {
      owner = "Stability-AI";
      repo = "generative-models";
      rev = "45c443b316737a4ab6e40413d7794a7f5657c19f";
      hash = "sha256-qaZeaCfOO4vWFZZAyqNpJbTttJy17GQ5+DM05yTLktA=";
    };
    k-diffusion = {
      owner = "crowsonkb";
      repo = "k-diffusion";
      rev = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c";
      hash = "sha256-tOWDFt0/hGZF5HENiHPb9a2pBlXdSvDvCNTsCMZljC4=";
    };
    BLIP = {
      owner = "salesforce";
      repo = "BLIP";
      rev = "48211a1594f1321b00f14c9f7a5b4813144b2fb9";
      hash = "sha256-0IO+3M/Gy4VrNBFYYgZB2CzWhT3PTGBXNKPad61px5k=";
    };
  };
  depsOut = lib.attrsets.mapAttrs (
    name: value:

    pkgs.srcOnly {
      inherit name;
      src = pkgs.fetchFromGitHub {
        inherit (value)
          owner
          repo
          rev
          hash
          ;
      };

    }
  ) deps;
in

pkgs.srcOnly {
  pname = "deps";
  version = "1.0";
  stdenv = pkgs.stdenvNoCC;
  sourceRoot = ".";

  # Empty derivation, nothing to build
  srcs = lib.attrsets.attrValues depsOut;

  # Attach other derivations or values
  passthru = depsOut;
}
