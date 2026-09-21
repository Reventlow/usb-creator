{
  description = "Create bootable USB installers for Linux and BSD with checksum and GPG verification";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Single source of truth: the VERSION= line in the script. The release
      # routine bumps that line and PKGBUILD's pkgver; nothing here to keep in
      # step. Matched per line, as a whole line: a file-wide greedy match
      # would land on the sed pattern in the self-update code, and a prefix
      # match would accept OMARCHY_MIN_VERSION.
      version =
        let
          lines = nixpkgs.lib.splitString "\n" (builtins.readFile ./usb-creator);
          hits = builtins.filter (m: m != null) (map (l: builtins.match ''VERSION="([^"]+)"'' l) lines);
        in
        builtins.head (builtins.head hits);
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "usb-creator";
          inherit version;
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            install -Dm755 usb-creator "$out/bin/usb-creator"
            install -Dm644 docs/usb-creator.1 "$out/share/man/man1/usb-creator.1"
            runHook postInstall
          '';

          # The script shells out to these by name. On NixOS none of them are
          # guaranteed in a user's PATH, so pin them in. sudo is deliberately
          # NOT wrapped: it must be the system's setuid binary, which
          # security.sudo provides on the host.
          postFixup = ''
            wrapProgram "$out/bin/usb-creator" \
              --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ bash coreutils gawk gnugrep gnused util-linux curl jq gnupg ])}
          '';

          meta = with pkgs.lib; {
            description = "Create bootable USB installers for Linux and BSD with checksum and GPG verification";
            homepage = "https://github.com/Reventlow/usb-creator";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "usb-creator";
          };
        };
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/usb-creator";
          meta.description = "Create bootable USB installers for Linux and BSD";
        };
      });
    };
}
