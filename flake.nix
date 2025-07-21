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

          # Use fetchurl with the latest archive
          src = pkgs.fetchurl {
            url = "https://github.com/luisbocanegra/kurve/archive/refs/heads/main.tar.gz";
            sha256 = "sha256-OTUEYluS35wPCQMqqEd+sdqBMhj/qrrM9Zwir0UKdns=";
          };

          # Don't build anything, just package the files
          dontConfigure = true;
          dontBuild = true;
          dontFixup = true;
          dontWrapQtApps = true;

          # Runtime dependencies that should be available
          propagatedBuildInputs = with pkgs; [
            cava
            python3Packages.websockets
            kdePackages.qtwebsockets
          ];

          installPhase = ''
            runHook preInstall
            
            # Create the plasmoid directory
            mkdir -p $out/share/plasma/plasmoids/org.kde.kurve
            
            # Copy the package directory contents
            if [ -d "package" ]; then
              cp -r package/* $out/share/plasma/plasmoids/org.kde.kurve/
            else
              # Fallback: copy everything and clean up
              cp -r . $out/share/plasma/plasmoids/org.kde.kurve/
              # Remove unwanted files
              find $out/share/plasma/plasmoids/org.kde.kurve -name ".git*" -exec rm -rf {} + 2>/dev/null || true
              find $out/share/plasma/plasmoids/org.kde.kurve -name "*.md" -delete 2>/dev/null || true
              find $out/share/plasma/plasmoids/org.kde.kurve -name "*.sh" -delete 2>/dev/null || true
              find $out/share/plasma/plasmoids/org.kde.kurve -name "CMakeLists.txt" -delete 2>/dev/null || true
              rm -rf $out/share/plasma/plasmoids/org.kde.kurve/build 2>/dev/null || true
            fi
            
            # Ensure we have a metadata file
            if [ ! -f "$out/share/plasma/plasmoids/org.kde.kurve/metadata.json" ] && [ ! -f "$out/share/plasma/plasmoids/org.kde.kurve/metadata.desktop" ]; then
              cat > $out/share/plasma/plasmoids/org.kde.kurve/metadata.json << 'EOF'
{
    "KPlugin": {
        "Authors": [{"Email": "", "Name": "luisbocanegra"}],
        "Category": "Multimedia",
        "Description": "Audio visualizer widget powered by CAVA",
        "Icon": "applications-multimedia",
        "Id": "org.kde.kurve",
        "License": "GPL-3.0+",
        "Name": "Kurve",
        "ServiceTypes": ["Plasma/Applet"],
        "Version": "1.0.0",
        "Website": "https://github.com/luisbocanegra/kurve"
    },
    "X-Plasma-API": "declarativeappletscript",
    "X-Plasma-MainScript": "ui/main.qml"
}
EOF
            fi
            
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
            cava
            python3Packages.websockets
            kdePackages.qtwebsockets
            kdePackages.libplasma
          ];
          
          shellHook = ''
            echo "Kurve development environment"
            echo "Runtime dependencies are available:"
            echo "- cava: $(which cava)"
            echo "- python websockets: available"
            echo "- Qt6 websockets: available"
          '';
        };

        # Simplified Home Manager module
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
                pkgs.python3Packages.websockets
                pkgs.kdePackages.qtwebsockets
              ];
              
              # Set up environment for QML plugin support
              home.sessionVariables = {
                QML_IMPORT_PATH = "$HOME/.local/lib64/qml:$HOME/.local/lib/qml:$QML_IMPORT_PATH";
              };
            };
          };
      }
    );
}
