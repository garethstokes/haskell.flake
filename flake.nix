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

        # Exported packages for composition
        haskellPackages = with pkgs; [
          ghc
          cabal-install
          haskell-language-server
          postgresql
        ];

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

          packages = haskellPackages;

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
              packages = haskellPackages ++ additionalPackages;
              shellHook = haskellShellHook + "\n" + additionalShellHook;
            };

          # Export components for manual composition
          inherit haskellPackages haskellShellHook;
        };

        # Backwards compatibility
        devShell = self.devShells.${system}.default;
      }
    );
}
