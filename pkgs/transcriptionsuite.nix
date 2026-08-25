{ appimageTools
, fetchurl
, lib
, makeDesktopItem
, symlinkJoin
, runCommand
, hicolor-icon-theme
}:

let
  version = "1.3.6";   # Check latest at https://github.com/homelab-00/TranscriptionSuite/releases
  pname = "transcriptionsuite";

  src = fetchurl {
    url = "https://github.com/homelab-00/TranscriptionSuite/releases/download/v${version}/TranscriptionSuite-${version}.AppImage";
    hash = ""; # Replace with the correct SHA256 after first build
  };

  # Wrap the AppImage so it runs on NixOS
  wrapped = appimageTools.wrapType2 {
    inherit pname version src;
  };

  # Desktop entry – Icon set to just the name (will be resolved by the system)
  desktopItem = makeDesktopItem {
    name = pname;
    exec = "${wrapped}/bin/${pname}";
    icon = pname;
    desktopName = "TranscriptionSuite";
    comment = "Fully local Speech‑to‑Text with speaker diarization";
    categories = [ "AudioVideo" "Utility" ];
    type = "Application";
    startupNotify = true;
  };

  # Provide an icon – use the one from the AppImage if present, otherwise a generic one
  icon = runCommand "${pname}-icon" { } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    if [ -e "${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png" ]; then
      cp "${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png" \
         "$out/share/icons/hicolor/256x256/apps/${pname}.png"
    else
      cp "${hicolor-icon-theme}/share/icons/hicolor/256x256/status/audio-volume-high.png" \
         "$out/share/icons/hicolor/256x256/apps/${pname}.png"
    fi
  '';

in symlinkJoin {
  name = "${pname}-${version}";
  paths = [ wrapped desktopItem icon ];
  meta = with lib; {
    description = "Fully local and private Speech-To-Text app with speaker diarization";
    homepage = "https://github.com/homelab-00/TranscriptionSuite";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
