{ appimageTools, fetchurl, lib }:

let
  version = "1.3.9"; # Replace with the actual latest version
in
appimageTools.wrapType2 {
  pname = "transcriptionsuite";
  inherit version;

  src = fetchurl {
    url = "https://github.com/homelab-00/TranscriptionSuite/releases/download/v${version}/TranscriptionSuite-${version}.AppImage";
    hash = "sha256-Qzv3fMozD2SACMybD+iKZ1i1XqYBQ4usATJ3bOpOttY="; # After first build, replace with the actual SHA256 hash
  };

  meta = with lib; {
    description = "Fully local and private Speech-To-Text app with speaker diarization";
    homepage = "https://github.com/homelab-00/TranscriptionSuite";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
