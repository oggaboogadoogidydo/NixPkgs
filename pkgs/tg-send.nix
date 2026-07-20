{ pkgs ? import <nixpkgs> {}
, rev ? "main"                                 # or a specific commit/tag
, sha256 ? "sha256-jiKfkmfB9+AowPGyHXvWzGEY6nZTyBq/HO3XgWSGUJk="   # replace with actual hash
}:

let
  # Fetch the tg-send script from its own GitHub repo
  src = pkgs.fetchFromGitHub {
    owner = "oggaboogadoogidydo";                    # change to actual owner
    repo = "tg-send";                          # change to actual repo name
    rev = rev;
    sha256 = sha256;
  };
in
pkgs.stdenv.mkDerivation {
  name = "tg-send";
  src = src;

  dontBuild = true;

  installPhase = ''
    # Install the main script
    mkdir -p $out/bin
    cp tg-send $out/bin/
    chmod +x $out/bin/tg-send

    # Wrap with runtime dependencies (curl, jq)
    wrapProgram $out/bin/tg-send \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.curl pkgs.jq ]}

    # Install a sample configuration file
    mkdir -p $out/share/doc/tg-send
    cat > $out/share/doc/tg-send/config.example <<EOF
# Telegram bot token (get from @BotFather)
TOKEN="your_bot_token_here"

# Chat ID (can be a user ID, group ID, or channel ID)
CHAT_ID="your_chat_id_here"

# Optional: default parse mode (HTML, Markdown, MarkdownV2)
# PARSE_MODE="HTML"
EOF
  '';

  nativeBuildInputs = [ pkgs.makeWrapper ];

  meta = with pkgs.lib; {
    description = "Send messages and files to a Telegram bot from the command line";
    license = licenses.mit;
    maintainers = [ maintainers.yourname ];
    platforms = platforms.all;
  };
}
