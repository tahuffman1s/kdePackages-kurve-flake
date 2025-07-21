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
            rev = "main"; # You may want to pin to a specific commit/tag
            hash = "sha256-dooCFcyY8dmSjnyFmAy+krXG38b1BSgTetyx9BY5iCQ="; # Replace with actual hash
          };

          nativeBuildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            pkg-config
            kdePackages.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            # KDE/Qt6 dependencies
            kdePackages.qtbase
            kdePackages.qtwebsockets
            kdePackages.libplasma
            kdePackages.kconfig
            kdePackages.kcoreaddons
            kdePackages.ki18n
            kdePackages.kpackage
            kdePackages.kservice
            kdePackages.plasma5support
            
            # Runtime dependencies
            cava
            python3Packages.websockets
            
            # Build dependencies
            gcc
          ];

          propagatedBuildInputs = with pkgs; [
            # These need to be available at runtime
            cava
            kdePackages.qtwebsockets
            python3Packages.websockets
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
            "-DKDE_INSTALL_USE_QT_SYS_PATHS=ON"
          ];

          # Install script handling
          preConfigure = ''
            # Make install script executable if it exists
            if [ -f install.sh ]; then
              chmod +x install.sh
            fi
          '';

          buildPhase = ''
            runHook preBuild
            
            # Check if there's a CMakeLists.txt for C++ plugin
            if [ -f CMakeLists.txt ]; then
              cmake -B build -S . $cmakeFlags
              cmake --build build
            fi
            
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/share/plasma/plasmoids
            
            # Install the C++ plugin if built
            if [ -d build ]; then
              cmake --install build --prefix $out
            fi
            
            # Install the plasmoid package
            if [ -d package ]; then
              cp -r package $out/share/plasma/plasmoids/org.kde.kurve
            elif [ -d plasmoid ]; then
              cp -r plasmoid $out/share/plasma/plasmoids/org.kde.kurve
            else
              # Fallback: copy all QML and metadata files
              cp -r . $out/share/plasma/plasmoids/org.kde.kurve
              # Clean up non-plasmoid files
              rm -rf $out/share/plasma/plasmoids/org.kde.kurve/{.git*,*.md,install.sh,CMakeLists.txt,build}
            fi
            
            # Ensure metadata.desktop exists and has correct name
            if [ ! -f "$out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop" ] && [ -f "$out/share/plasma/plasmoids/org.kde.kurve/metadata.json" ]; then
              # Convert metadata.json to metadata.desktop if needed
              echo "[Desktop Entry]" > $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
              echo "Type=Service" >> $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
              echo "X-KDE-ServiceTypes=Plasma/Applet" >> $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
              echo "X-KDE-PluginInfo-Name=org.kde.kurve" >> $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
              echo "X-KDE-PluginInfo-Category=Multimedia" >> $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
              echo "Name=Kurve" >> $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
              echo "Comment=Audio visualizer widget powered by CAVA" >> $out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop
            fi
            
            runHook postInstall
          '';

          # Set up environment for the C++ plugin
          postInstall = ''
            # Create wrapper script to set QML_IMPORT_PATH if C++ plugin is built
            if [ -d "$out/lib64/qml" ] || [ -d "$out/lib/qml" ]; then
              mkdir -p $out/bin
              cat > $out/bin/kurve-setup-env << 'EOF'
            #!/bin/bash
            export QML_IMPORT_PATH="$1/lib64/qml:$1/lib/qml:$QML_IMPORT_PATH"
            echo "QML_IMPORT_PATH set for Kurve C++ plugin support"
            echo "Add this to your ~/.config/plasma-workspace/env/path.sh:"
            echo "export QML_IMPORT_PATH=\"$1/lib64/qml:$1/lib/qml:\$QML_IMPORT_PATH\""
            EOF
              chmod +x $out/bin/kurve-setup-env
            fi
          '';

          meta = with pkgs.lib; {
            description = "Audio visualizer widget powered by CAVA for KDE Plasma Desktop";
            longDescription = ''
              Kurve is a KDE Plasma 6 widget that provides real-time audio visualization
              powered by CAVA. It features customizable visual effects and integrates
              seamlessly with the Plasma desktop environment.
              
              The widget supports both QML-only mode (using Qt/Python WebSockets to
              communicate with CAVA) and an optional C++ plugin for enhanced performance.
            '';
            homepage = "https://github.com/luisbocanegra/kurve";
            license = licenses.gpl3Plus;
            maintainers = [ ];
            platforms = platforms.linux;
            broken = false;
          };
        };

        # Development shell with all dependencies
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Build tools
            cmake
            extra-cmake-modules
            pkg-config
            gcc
            git
            
            # KDE/Qt6 development
            kdePackages.qtbase
            kdePackages.qtwebsockets
            kdePackages.libplasma
            kdePackages.kconfig
            kdePackages.kcoreaddons
            kdePackages.ki18n
            kdePackages.kpackage
            kdePackages.kservice
            kdePackages.kpackagetool
            kdePackages.plasma5support
            
            # Runtime dependencies
            cava
            python3Packages.websockets
            
            # Development tools
            kdePackages.plasma-sdk
            kdePackages.kirigami
          ];
          
          shellHook = ''
            echo "Kurve development environment"
            echo "Available tools:"
            echo "  - cmake, gcc: Build system"
            echo "  - kpackagetool6: Install/manage plasmoids"
            echo "  - cava: Audio visualizer backend"
            echo "  - Qt6/KDE libraries: UI framework"
            echo ""
            echo "To install the widget locally:"
            echo "  kpackagetool6 -t Plasma/Applet -i package"
            echo ""
            echo "To test with CAVA:"
            echo "  cava -p /path/to/cava/config"
          '';
        };

        # Home Manager module for easy installation
        homeManagerModule = { config, lib, pkgs, ... }:
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
              
              autoInstall = mkOption {
                type = types.bool;
                default = true;
                description = "Automatically install the widget to Plasma";
              };
              
              cavaConfig = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Path to custom CAVA configuration file";
              };
            };
            
            config = mkIf cfg.enable {
              home.packages = [ 
                cfg.package 
                pkgs.cava
                pkgs.kdePackages.qtwebsockets
                pkgs.python3Packages.websockets
              ];
              
              # Install the plasmoid
              home.activation.kurveInstall = mkIf cfg.autoInstall (
                lib.hm.dag.entryAfter ["writeBoundary"] ''
                  if command -v kpackagetool6 >/dev/null 2>&1; then
                    $DRY_RUN_CMD ${pkgs.kdePackages.kpackagetool}/bin/kpackagetool6 \
                      -t Plasma/Applet -u ${cfg.package}/share/plasma/plasmoids/org.kde.kurve || \
                    $DRY_RUN_CMD ${pkgs.kdePackages.kpackagetool}/bin/kpackagetool6 \
                      -t Plasma/Applet -i ${cfg.package}/share/plasma/plasmoids/org.kde.kurve
                  fi
                ''
              );
              
              # Set up CAVA config if provided
              xdg.configFile."cava/config" = mkIf (cfg.cavaConfig != null) {
                source = cfg.cavaConfig;
              };
              
              # Set up environment for C++ plugin
              home.sessionVariables = {
                QML_IMPORT_PATH = "$HOME/.local/lib64/qml:$HOME/.local/lib/qml:${cfg.package}/lib64/qml:${cfg.package}/lib/qml:$QML_IMPORT_PATH";
              };
            };
          };

      in {
        packages = {
          default = kurve;
          kurve = kurve;
        };

        devShells.default = devShell;

        # Export the Home Manager module
        homeManagerModules = {
          kurve = homeManagerModule;
          default = homeManagerModule;
        };
        
        # NixOS module
        nixosModules = {
          kurve = { config, lib, pkgs, ... }:
            with lib;
            let
              cfg = config.services.kurve;
            in {
              options.services.kurve = {
                enable = mkEnableOption "Kurve audio visualizer support";
                
                package = mkOption {
                  type = types.package;
                  default = kurve;
                  description = "The Kurve package to use";
                };
              };
              
              config = mkIf cfg.enable {
                environment.systemPackages = with pkgs; [
                  cfg.package
                  cava
                  kdePackages.qtwebsockets
                  python3Packages.websockets
                  kdePackages.kpackagetool
                ];
                
                # Ensure required services are available
                services.pulseaudio.enable = mkDefault true;
                services.pipewire = mkIf (!config.services.pulseaudio.enable) {
                  enable = mkDefault true;
                  pulse.enable = mkDefault true;
                };
              };
            };

          default = self.nixosModules.${system}.kurve;
        };
      }
    );
}
