# Kurve NixOS Flake

A NixOS flake for [Kurve](https://github.com/luisbocanegra/kurve), an audio visualizer widget powered by CAVA for the KDE Plasma Desktop.

## Features

🎵 **Audio Visualization**: Real-time audio spectrum visualization using CAVA  
🖥️ **Plasma Integration**: Seamlessly integrates with KDE Plasma 6 desktop  
⚡ **Dual Mode Support**: Works with both QML-only mode and optional C++ plugin  
📦 **Complete Dependencies**: Automatically handles all runtime and build dependencies  
🏠 **Home Manager Ready**: Easy user-level installation and configuration  
🛠️ **Development Environment**: Full dev shell with all necessary tools

## Quick Start

### 1. Build and Install

```bash
# Clone this flake
git clone https://github.com/tahuffman1s/kdePackages-kurve-flake.git
cd kdePackages-kurve-flake

# Build the package
nix build

# Install to your profile
nix profile install .#kurve
```

### 2. Install Widget to Plasma

```bash
# Install the plasmoid to your Plasma desktop
kpackagetool6 -t Plasma/Applet -i ./result/share/plasma/plasmoids/org.kde.kurve

# Or update if already installed
kpackagetool6 -t Plasma/Applet -u ./result/share/plasma/plasmoids/org.kde.kurve
```

### 3. Add to Desktop

1. Right-click on your Panel or Desktop
2. Select "Add or manage widgets"
3. Search for "Kurve"
4. Add it to your Panel or Desktop

## Usage Options

### Option 1: Direct Flake Usage

```bash
# Build
nix build github:tahuffman1s/kdePackages-kurve-flake

# Development environment
nix develop github:tahuffman1s/kdePackages-kurve-flake

# Run in a temporary shell
nix shell github:tahuffman1s/kdePackages-kurve-flake
```

### Option 2: Home Manager Integration

Add to your `home.nix` or `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kurve-flake.url = "github:tahuffman1s/kdePackages-kurve-flake";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, kurve-flake, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        kurve-flake.homeManagerModules.default
        {
          programs.kurve = {
            enable = true;
            autoInstall = true;  # Automatically install to Plasma
            cavaConfig = ./path/to/your/cava-config;  # Optional
          };
        }
      ];
    };
  };
}
```

### Option 3: NixOS System Integration

Add to your `configuration.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kurve-flake.url = "github:tahuffman1s/kdePackages-kurve-flake";
  };

  outputs = { nixpkgs, kurve-flake, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        kurve-flake.nixosModules.default
        {
          services.kurve.enable = true;
        }
      ];
    };
  };
}
```

## Development

### Development Shell

```bash
# Enter development environment
nix develop

# Available tools in dev shell:
# - cmake, gcc: Build system
# - kpackagetool6: Install/manage plasmoids  
# - cava: Audio visualizer backend
# - Qt6/KDE libraries: UI framework
```

### Manual Build Process

```bash
# Clone the original repository
git clone https://github.com/luisbocanegra/kurve.git
cd kurve

# Enter development shell
nix develop github:tahuffman1s/kdePackages-kurve-flake

# Build manually
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=~/.local
make && make install

# Install plasmoid
kpackagetool6 -t Plasma/Applet -i ../package
```

## Configuration

### CAVA Configuration

Kurve uses CAVA for audio visualization. You can customize the visualization by creating a CAVA config file:

```bash
# Create CAVA config directory
mkdir -p ~/.config/cava

# Copy default config
cp /etc/cava/config ~/.config/cava/config

# Edit to your preferences
nano ~/.config/cava/config
```

### C++ Plugin Support

For enhanced performance, Kurve includes an optional C++ plugin. The flake automatically sets up the required environment:

```bash
# The QML_IMPORT_PATH is automatically configured
# If you need to set it manually:
export QML_IMPORT_PATH="$HOME/.local/lib64/qml:$HOME/.local/lib/qml:$QML_IMPORT_PATH"
```

## Dependencies

### Runtime Dependencies
- **CAVA**: Audio spectrum analyzer
- **Qt6 WebSockets**: Communication with CAVA (fallback mode)
- **Python WebSockets**: Alternative communication method
- **KDE Plasma 6**: Desktop environment

### Build Dependencies
- **CMake**: Build system
- **Extra CMake Modules**: KDE build extensions
- **GCC**: C++ compiler
- **KDE/Qt6 Development Libraries**: UI framework libraries

## Troubleshooting

### Widget Not Appearing
```bash
# Check if the widget is installed
kpackagetool6 -t Plasma/Applet -l | grep kurve

# Reinstall if necessary
kpackagetool6 -t Plasma/Applet -r org.kde.kurve
kpackagetool6 -t Plasma/Applet -i ./result/share/plasma/plasmoids/org.kde.kurve
```

### Audio Not Working
```bash
# Test CAVA directly
cava

# Check audio system
pactl info  # For PulseAudio
wpctl status  # For PipeWire
```

### C++ Plugin Issues
```bash
# Check QML import path
echo $QML_IMPORT_PATH

# Verify plugin installation
ls ~/.local/lib*/qml/
```

## Contributing

1. Fork this repository
2. Make your changes
3. Test with `nix build` and `nix develop`
4. Submit a pull request

## License

This flake follows the same license as the original Kurve project (GPL-3.0+).

## Credits

- **Original Project**: [Kurve by luisbocanegra](https://github.com/luisbocanegra/kurve)
- **CAVA**: [Audio spectrum analyzer](https://github.com/karlstav/cava)
- **Flake Maintainer**: [tahuffman1s](https://github.com/tahuffman1s)

## Support

- 🐛 **Issues**: [Report bugs](https://github.com/tahuffman1s/kurve-flake/issues)
- 💬 **Discussions**: [Ask questions](https://github.com/tahuffman1s/kurve-flake/discussions)
- 📖 **Original Docs**: [Kurve README](https://github.com/luisbocanegra/kurve/blob/main/README.md)
