{ lib
, stdenv
, fetchFromGitHub
, python3
}:

stdenv.mkDerivation rec {
  pname = "tg-send";
  version = "unstable-2026-08-25";   # replace with a real date or tag

  src = fetchFromGitHub {
    owner = "oggaboogadoogidydo";
    repo = "tg-send";
    rev = "main";                     # pin to a specific commit for reproducibility
    sha256 = "sha256-V+HC8D1j4rHBDyvqmYJFjgWVIQDJlxSiECpfLCaVx0Y=";          # replace with actual src hash after first build
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/tg-send $out/share/tg-send

    # Locate the main script – it should be named "tg-send" (no extension)
    script_file=$(find $src -maxdepth 1 -type f -name "tg-send" | head -n1)
    if [ -z "$script_file" ]; then
      echo "Error: Could not find the script file 'tg-send' in the source." >&2
      exit 1
    fi

    cp "$script_file" $out/libexec/tg-send/tg-send
    chmod +x $out/libexec/tg-send/tg-send

    # Patch shebang to use the exact Python interpreter from nixpkgs
    substituteInPlace $out/libexec/tg-send/tg-send \
      --replace "#!/usr/bin/env python3" "#!${python3.interpreter}"

    # Install a default configuration file (template)
    cat > $out/share/tg-send/config.default <<'EOF'
# Default configuration for tg-send
# Edit this file to suit your needs.
# It will be copied to ~/.config/tg-send/config when the wrapper runs.
token = YOUR_BOT_TOKEN
chat_id = YOUR_CHAT_ID
retries = 3        # optional; defaults to 3 if omitted
EOF

    # Create the wrapper script that ensures a user config exists
    cat > $out/bin/tg-send <<'WRAPPER'
#!${stdenv.shell}
CONFIG_DIR="$HOME/.config/tg-send"
CONFIG_FILE="$CONFIG_DIR/config"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    cp "@defaultConfig@" "$CONFIG_FILE"
    echo "Created default config at $CONFIG_FILE" >&2
    echo "Please edit it to set your token and chat_id." >&2
fi

exec "@realBinary@" "$@"
WRAPPER

    substituteInPlace $out/bin/tg-send \
      --replace '@defaultConfig@' "$out/share/tg-send/config.default" \
      --replace '@realBinary@' "$out/libexec/tg-send/tg-send"

    chmod +x $out/bin/tg-send

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple Linux command-line tool to send messages to Telegram via a bot";
    homepage = "https://github.com/oggaboogadoogidydo/tg-send";
    # The repository does not specify a license; replace with the actual one (e.g., "mit", "gpl3", etc.)
    license = licenses.mit;
    maintainers = [ maintainers.me ];
    platforms = platforms.unix;
  };
}
