{ appimageTools, fetchurl, lib, makeDesktopItem, symlinkJoin }:

let
  version = "1.3.6";   # Check latest at https://github.com/homelab-00/TranscriptionSuite/releases
  pname = "transcriptionsuite";

  # 1. Fetch the AppImage
  src = fetchurl {
    url = "https://github.com/homelab-00/TranscriptionSuite/releases/download/v${version}/TranscriptionSuite-${version}.AppImage";
    hash = "sha256-12bc1f9p4v55q4pg7a5f5swff247b8y91pnm84vkbzpxf886j36r="; # Replace with the correct SHA256 after the first build
  };

  # 2. Wrap the AppImage (makes it runnable on NixOS)
  wrapped = appimageTools.wrapType2 {
    inherit pname version src;
    # extraPkgs is optional – wrapType2 already pulls in fuse and required libs
    extraPkgs = pkgs: [ ];
  };

  # 3. Build a .desktop file – use the icon from the wrapped package if it exists,
  #    otherwise point to a fallback (we'll provide one later).
  desktopItem = makeDesktopItem {
    name = pname;
    exec = "${wrapped}/bin/${pname}";
    # Try to use the icon that wrapType2 may have extracted.
    # If it doesn't exist, we'll symlink a generic one in the final step.
    icon = "${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png";
    desktopName = "TranscriptionSuite";
    comment = "Fully local Speech‑to‑Text with speaker diarization";
    categories = [ "AudioVideo" "Utility" ];
    type = "Application";
    startupNotify = true;
  };

  # 4. Provide a generic fallback icon in case the AppImage doesn't ship one.
  fallbackIcon = pkgs.runCommand "transcriptionsuite-icon" { } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    # Copy a standard audio icon from the hicolor theme (or any other)
    cp ${pkgs.hicolor-icon-theme}/share/icons/hicolor/256x256/status/audio-volume-high.png \
       $out/share/icons/hicolor/256x256/apps/${pname}.png
  '';

in
# 5. Merge everything into one output that contains bin/, share/applications/, share/icons/
symlinkJoin {
  name = "${pname}-${version}";
  paths = [
    wrapped
    desktopItem
    fallbackIcon   # ensures at least one icon exists
  ];
  buildInputs = [ makeDesktopItem ];
  postBuild = ''
    # The desktop file from makeDesktopItem is already in share/applications.
    # But its Exec path points to the wrapped binary in the store – that's fine.
    # We ensure the icon referenced in the desktop file exists.
    # If the wrapped AppImage provided its own icon, it will take precedence
    # because we symlink wrapped first (order in paths matters? Actually symlinkJoin
    # will not override, it will give a conflict. So we need to handle this carefully.)
    # Better: copy the desktop file and adjust Icon path to a guaranteed location.
    # We'll just copy the desktop file from desktopItem and modify the Icon line
    # to point to our fallback icon, but we also want to use the original if it exists.
    # Simpler: we will create a new desktop file that points to an icon we know exists.
    # Let's override the desktop file.
    mkdir -p $out/share/applications
    # Use the desktop file from desktopItem but replace Icon with our fallback
    # (or we could keep the original if we symlink the original icon to that path)
    # Let's just copy the fallback icon to the path that the desktop file expects.
    # The desktop file expects ${pname}.png in the standard hicolor path.
    # We already have fallbackIcon providing that, and wrapped might also.
    # We'll simply ensure that the icon is available in $out/share/icons/hicolor/256x256/apps/${pname}.png
    # by symlinking from the fallback or from wrapped if present.
    if [ -e ${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png ]; then
      # If wrapped has it, use that
      mkdir -p $out/share/icons/hicolor/256x256/apps
      ln -sf ${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png $out/share/icons/hicolor/256x256/apps/${pname}.png
    else
      # otherwise use fallback
      mkdir -p $out/share/icons/hicolor/256x256/apps
      ln -sf ${fallbackIcon}/share/icons/hicolor/256x256/apps/${pname}.png $out/share/icons/hicolor/256x256/apps/${pname}.png
    fi
    # Now copy the desktop file and adjust its Icon path to be relative (or absolute)
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
    # Update the Icon line to point to the icon we just placed
    substituteInPlace $out/share/applications/*.desktop \
      --replace "Icon=${wrapped}/share/icons/hicolor/256x256/apps/${pname}.png" \
                "Icon=${pname}"
    # The desktop entry spec says Icon can be just the name, it will be looked up in standard dirs.
  '';
  meta = with lib; {
    description = "Fully local and private Speech-To-Text app with speaker diarization";
    homepage = "https://github.com/homelab-00/TranscriptionSuite";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
