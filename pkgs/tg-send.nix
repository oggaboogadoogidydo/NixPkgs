{ lib
, buildGoModule
, fetchFromGitHub
, stdenv
}:

buildGoModule rec {
  pname = "tg-send";
  version = "unstable-2026-08-25";   # update to a real date or tag

  src = fetchFromGitHub {
    owner = "oggaboogadoogidydo";
    repo = "tg-send";
    # Replace with a specific commit hash for reproducibility.
    # Use "main" only temporarily; compute the hash after first build.
    rev = "main";
    sha256 = lib.fakeSha256;          # replace with actual src hash after first build
  };

  # Replace with the actual vendor hash after the first build attempt.
  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  # Build the main package; adjust if the binary is in a subdirectory (e.g., cmd/tg-send)
  subPackages = [ "." ];

  postInstall = ''
    # Move the built binary to libexec so we can wrap it
    mkdir -p $out/libexec/tg-send
    mv $out/bin/tg-send $out/libexec/tg-send/tg-send

    # Install a default configuration file (example)
    mkdir -p $out/share/tg-send
    cat > $out/share/tg-send/config.default <<'EOF'
# Default configuration for tg-send
# Edit this file to suit your needs.
# It will be copied to ~/.config/tg-send/config when the wrapper runs.
EOF

    # Create the wrapper script that ensures a user config exists
    mkdir -p $out/bin
    cat > $out/bin/tg-send <<'WRAPPER'
#!${stdenv.shell}
CONFIG_DIR="$HOME/.config/tg-send"
CONFIG_FILE="$CONFIG_DIR/config"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    cp "@defaultConfig@" "$CONFIG_FILE"
    echo "Created default config at $CONFIG_FILE" >&2
fi

exec "@binary@" "$@"
WRAPPER

    # Substitute paths in the wrapper
    substituteInPlace $out/bin/tg-send \
      --replace '@defaultConfig@' "$out/share/tg-send/config.default" \
      --replace '@binary@' "$out/libexec/tg-send/tg-send"

    chmod +x $out/bin/tg-send
  '';

  meta = with lib; {
    description = "A tool to send messages via Telegram";
    homepage = "https://github.com/oggaboogadoogidydo/tg-send";
    # Replace with the actual license (e.g., mit, gpl, etc.)
    license = licenses.unfree;
    maintainers = [ maintainers.me ];
    platforms = platforms.unix;
  };
}
