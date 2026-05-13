{
  description = "Nix overlay for latest AWS SAM CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      versionData = builtins.fromJSON (builtins.readFile ./version.json);

      overlay = final: prev: {
        aws-sam-cli = prev.aws-sam-cli.overrideAttrs (old: {
          version = versionData.version;
          src = prev.fetchPypi {
            pname = "aws_sam_cli";
            version = versionData.version;
            hash = versionData.hash;
          };
          patches = [ ];
          postPatch = builtins.replaceStrings
            [ "requirements/base.txt" ]
            [ "pyproject.toml" ]
            old.postPatch;
          pythonRelaxDeps = old.pythonRelaxDeps ++ [ "jmespath" ];
          propagatedBuildInputs = old.propagatedBuildInputs ++ [
            prev.python3Packages.python-dotenv
          ];
          doCheck = false;
          doInstallCheck = false;
        });
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system}.extend overlay;
        in
        {
          aws-sam-cli = pkgs.aws-sam-cli;
          default = pkgs.aws-sam-cli;
        }
      );

      overlays.default = overlay;
    };
}
