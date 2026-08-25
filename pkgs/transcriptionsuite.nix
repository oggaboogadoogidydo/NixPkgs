{ appimageTools, fetchurl, lib, makeDesktopItem, symlinkJoin, pkgs }:

let
  version = "1.3.6";   # Check latest at https://github.com/homelab-00/TranscriptionSuite/releases
  pname = "transcriptionsuite";

  src = fetchurl {
    url = "https://github.com/homelab-00/TranscriptionSuite/releases/download/v${version}/TranscriptionSuite-${version}.AppImage";
    hash = ""; # Replace with actual SHA256 after first build
  };

  wrapped = appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs = _: [ ];   # no extra packages needed
  };

  desktopItem = makeDesktopItem {
    name = pname;
    exec = "${wrapped}/bin/${pname}";
    icon = "${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png";
    desktopName = "TranscriptionSuite";
    comment = "Fully local Speech‑to‑Text with speaker diarization";
    categories = [ "AudioVideo" "Utility" ];
    type = "Application";
    startupNotify = true;
  };

  fallbackIcon = pkgs.runCommand "transcriptionsuite-icon" { } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${pkgs.hicolor-icon-theme}/share/icons/hicolor/256x256/status/audio-volume-high.png \
       $out/share/icons/hicolor/256x256/apps/${pname}.png
  '';

in
symlinkJoin {
  name = "${pname}-${version}";
  paths = [
    wrapped
    desktopItem
    fallbackIcon
  ];
  postBuild = ''
    # Ensure the icon is available at the location expected by the desktop file
    mkdir -p $out/share/icons/hicolor/256x256/apps
    if [ -e ${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png ]; then
      ln -sf ${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png \
             $out/share/icons/hicolor/256x256/apps/${pname}.png
    else
      ln -sf ${fallbackIcon}/share/icons/hicolor/256x256/apps/${pname}.png \
             $out/share/icons/hicolor/256x256/apps/${pname}.png
    fi
    # Copy the desktop file and adjust the Icon entry to just the name
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
    substituteInPlace $out/share/applications/*.desktop \
      --replace "Icon=${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png" \
                "Icon=${pname}"
  '';
  meta = with lib; {
    description = "Fully local and private Speech-To-Text app with speaker diarization";
    homepage = "https://github.com/homelab-00/TranscriptionSuite";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
