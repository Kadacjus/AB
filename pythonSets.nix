{
  lib,
  self,
  nixpkgs,
  pyproject-nix,
  pyproject-build-systems,
  uv2nix,
  uv2nix-hammer-overrides,
  ...
}:
# Python sets grouped per system
lib.flake.forAllSystems (
  system:
  let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = "${self}"; };

    overlay = workspace.mkPyprojectOverlay {
      sourcePreference = "wheel";
    };

    editableOverlay = workspace.mkEditablePyprojectOverlay {
      root = "$REPO_ROOT";
    };

    # Base Python package set from pyproject.nix
    baseSet = pkgs.callPackage pyproject-nix.build.packages {
      python = pkgs.python310;
    };

    # An overlay of build fixups & test additions
    pyprojectOverrides = final: prev: {
      sgm = prev.sgm.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          ++ final.resolveBuildSystem {
            hatchling = [ ];
          };
      });
      cv-3 = prev.cv-3.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          ++ final.resolveBuildSystem {
            setuptools = [ ];
          };
      });
    };

  in
  (baseSet.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      overlay
      (uv2nix-hammer-overrides.overrides pkgs)
      pyprojectOverrides
    ]
  ))
)
