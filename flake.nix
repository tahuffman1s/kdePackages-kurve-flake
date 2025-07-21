{
  description = "Kurve - Audio visualizer widget powered by CAVA for KDE Plasma Desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        kurve = pkgs.stdenv.mkDerivation rec {
          pname = "kurve";
          version = "1.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "luisbocanegra";
            repo = "kurve";
            rev = "main";
            sha256 = "sha256-dooCFcyY8dmSjnyFmAy+krXG38b1BSgTetyx9BY5iCQ=";
          };

          nativeBuildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            kdePackages.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            kdePackages.qtbase
            kdePackages.qtwebsockets
            kdePackages.libplasma
            kdePackages.kconfig
            kdePackages.kcoreaddons
            kdePackages.ki18n
            kdePackages.kpackage
            kdePackages.kservice
            cava
            python3Packages.websockets
          ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/share/plasma/plasmoids/org.kde.kurve
            
            # Copy the package directory
            if [ -d "package" ]; then
              cp -r package/* $out/share/plasma/plasmoids/org.kde.kurve/
            else
              cp -r . $out/share/plasma/plasmoids/org.kde.kurve/
              rm -rf $out/share/plasma/plasmoids/org.kde.kurve/{.git*,*.md,*.sh,CMakeLists.txt,build}
            fi
            
            # Create install helper script
            mkdir -p $out/bin
            cat > $out/bin/kurve-install << 'EOF'
#!/bin/bash
echo "To install Kurve widget:"
echo "kpackagetool6 -t Plasma/Applet -i $out/share/plasma/plasmoids/org.kde.kurve"
EOF
            chmod +x $out/bin/kurve-install
            
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Audio visualizer widget powered by CAVA for KDE Plasma Desktop";
            homepage = "https://github.com/luisbocanegra/kurve";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
          };
        };

      in {
        packages = {
          default = kurve;
          kurve = kurve;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            kdePackages.qtbase
            kdePackages.qtwebsockets
            kdePackages.libplasma
            cava
            python3Packages.websockets
          ];
        };

        # Simple Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.programs.kurve;
          in {
            options.programs.kurve = {
              enable = mkEnableOption "Kurve audio visualizer widget";
              package = mkOption {
                type = types.package;
                default = kurve;
                description = "The Kurve package to use";
              };
            };
            
            config = mkIf cfg.enable {
              home.packages = [ 
                cfg.package 
                pkgs.cava
              ];
            };
          };
      }
    );
}
