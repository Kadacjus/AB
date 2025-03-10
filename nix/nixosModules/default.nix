{
  lib,
  self,
  nixpkgs,
  package-name,
  ...
}:
with lib;
let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  config = self.nixosModules.options;
in
{
  "${package-name}" =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.services.${package-name};
      inherit (pkgs) system;

      inherit (lib.options) mkOption;
      inherit (lib.modules) mkIf;
    in
    {
      options.services.${package-name} = {
        enable = mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable ${package-name}
          '';
        };
        args = mkOption {
          default = [
            "--skip-prepare-environment"
            "--xformers"
          ];
          type = types.listOf (types.str);
          description = "Command line arguments to pass to launch.py";
        };

        venv = mkOption {
          type = lib.types.package;
          default = self.packages.${system}.venv;
          description = ''
            ${package-name} virtual environment package
          '';
        };

        stateDir = mkOption {
          default = "/var/lib/${package-name}";
          type = types.str;
          description = "${package-name} data directory.";
        };
        repositoryRoot = mkOption {
          type = types.str;
          default = "${cfg.stateDir}/src";
          description = "Path to the git repositories.";
        };

      };
      config = mkIf cfg.enable {
        environment.systemPackages = [
          cfg.venv
          pkgs.git
          pkgs.cacert
          pkgs.rsync
        ];
        users.users.${package-name} = {
          description = "${package-name}-user";
          home = cfg.stateDir;
          group = package-name;
          isSystemUser = true;
        };
        users.groups.${package-name} = { };
        systemd.services.${package-name} = {
          description = "${package-name} server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          path = with pkgs; [
            gitAndTools.git
            cacert
            neovim
          ];
          preStart = ''
            mkdir -p ${cfg.repositoryRoot}/repositories
            mkdir -p ${cfg.stateDir}/.config/matplotlib
            ${lib.getExe pkgs.rsync} -r -a ${
              self.packages.${system}.${package-name}.static
            }/* ${cfg.repositoryRoot}
            chown -hR ${package-name} ${cfg.stateDir}
            chmod -R +775 ${cfg.stateDir}
          '';

          serviceConfig = {
            ExecStart = ''
              ${cfg.venv}/bin/python ${cfg.repositoryRoot}/launch.py ${builtins.concatStringsSep " " cfg.args}
            '';
            Restart = "on-failure";
            User = package-name;

            # DynamicUser = true;
            StateDirectory = "${cfg.stateDir}";
            StateDirectoryMode = 775;
            RuntimeDirectory = "${cfg.repositoryRoot}";
            RuntimeDirectoryMode = 775;
            PermissionsStartOnly = true;

            # BindReadOnlyPaths = [
            #   "${
            #     config.environment.etc."ssl/certs/ca-certificates.crt".source
            #   }:/etc/ssl/certs/ca-certificates.crt"
            #   builtins.storeDir
            #   "-/etc/resolv.conf"
            #   "-/etc/nsswitch.conf"
            #   "-/etc/hosts"
            #   "-/etc/localtime"
            # ];
          };

        };
      };

    };

}
