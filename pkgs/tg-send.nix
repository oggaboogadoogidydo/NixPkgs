{ stdenv
, python3
, fetchFromGitHub
, makeWrapper
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.requests ]);
in
stdenv.mkDerivation rec {
  pname = "tg-send";
  version = "unstable-2024-12-20";  # use the latest commit date

  src = fetchFromGitHub {
    owner = "oggaboogadoogidydo";
    repo = "tg-send";
    rev = "main";
    sha256 = "sha256-jiKfkmfB9+AowPGyHXvWzGEY6nZTyBq/HO3XgWSGUJk=";  # replace with actual hash
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    # Install the script
    install -Dm755 tg-send $out/bin/tg-send-real

    # Create a wrapper that:
    # 1. Creates ~/.config/tg-send/ with a template config if missing
    # 2. Runs the real script with the Python environment
    makeWrapper ${pythonEnv}/bin/python3 $out/bin/tg-send \
      --add-flags "$out/bin/tg-send-real" \
      --run 'if [ ! -f "$HOME/.config/tg-send/config" ]; then
               mkdir -p "$HOME/.config/tg-send"
               cat > "$HOME/.config/tg-send/config" <<EOF
# Telegram Bot Token – get one from @BotFather on Telegram
token = YOUR_BOT_TOKEN_HERE

# Chat ID – numeric ID or @username of the channel/group/user
chat_id = YOUR_CHAT_ID_HERE
EOF
               echo "Created default config file at ~/.config/tg-send/config"
               echo "Please edit it with your token and chat ID."
             fi'

    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Lightweight Linux command-line tool to send messages to Telegram via a bot";
    homepage = "https://github.com/oggaboogadoogidydo/tg-send";
    license = licenses.mit;  # adjust if a license is specified
    platforms = platforms.linux;
    maintainers = [ maintainers.yourname ];
  };
}
