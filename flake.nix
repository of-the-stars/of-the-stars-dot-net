{
  description = "A basic flake for dev environments and packaging";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        name = "of-the-stars (dot) net";
        src = ./.;
      in
      {
        devShells.default =
          with pkgs;
          mkShell {
            buildInputs = [
              hugo
              neocities
              just
            ];
            shellHook = '''';
          };
        # source <(hugo completion zsh)

        # packages.default = derivation {
        #   inherit system name src;
        #   builder = with pkgs; "${bash}/bin/bash";
        #   args = [
        #     "-c"
        #     "echo foo > $out"
        #   ];
        # };
      }
    );
}
