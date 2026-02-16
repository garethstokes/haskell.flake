{
  description = "Haskell development environment with GHC 9, HLS, and PostgreSQL client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Tools for development shells
        haskellDevTools = with pkgs; [
          ghc
          cabal-install
          haskell-language-server
          postgresql
        ];

        # Full haskellPackages set for building Cabal projects
        haskellPkgs = pkgs.haskellPackages;

        # PostgreSQL library path for psql client
        postgresLibPath = pkgs.lib.makeLibraryPath [ pkgs.postgresql.lib ];

        # Exported shell hook for composition
        haskellShellHook = ''
          # Add PostgreSQL libraries to LD_LIBRARY_PATH for psql client
          export LD_LIBRARY_PATH=${postgresLibPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
        '';

      in
      {
        # Standalone development shell
        devShells.default = pkgs.mkShell {
          name = "haskell-dev";

          packages = haskellDevTools;

          shellHook = ''
            ${haskellShellHook}

            # Welcome message
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "λ Haskell Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "GHC: $(ghc --version)"
            echo "Cabal: $(cabal --version | head -n1)"
            echo "HLS: $(haskell-language-server --version | head -n1)"
            echo "psql: $(psql --version | head -n1)"
            echo ""
            echo "🐘 PostgreSQL client (psql) available with library paths configured"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
          '';
        };

        # Export composable parts for other flakes
        lib = {
          # Function to create a Haskell-enabled shell
          mkHaskellShell = { additionalPackages ? [], additionalShellHook ? "" }:
            pkgs.mkShell {
              packages = haskellDevTools ++ additionalPackages;
              shellHook = haskellShellHook + "\n" + additionalShellHook;
            };

          # Full haskellPackages set for building Cabal projects with callCabal2nix
          inherit haskellPkgs;

          # Export components for manual composition (legacy names)
          haskellPackages = haskellDevTools;
          inherit haskellShellHook;
        };

        # Backwards compatibility
        devShell = self.devShells.${system}.default;
      }
    );
}
