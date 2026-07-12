{ lib
, buildNpmPackage
, fetchFromGitHub
, electron
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, nix-update-script
}:

buildNpmPackage rec {
  pname = "numara";
  version = "7.4.1";

  src = fetchFromGitHub {
    owner = "bornova";
    repo = "numara-calculator";
    rev = "v${version}";
    hash = "sha256-T1BKhNv1pvU4ZMPa/m6wgU1rassC1UIRp+Yfif+rjyk=";
  };

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  npmDepsHash = "sha256-4tOebTstCsCieIp8ZAik3/vyqCYqQNRwEw06PdHw2Kg=";

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/numara/electron
    mkdir -p $out/bin

    # Copy Electron main process source
    cp -r src/electron/* $out/lib/numara/electron/

    # Copy built renderer assets into electron/build/
    cp -r build $out/lib/numara/electron/

    # Copy all dependencies (node_modules)
    cp -r node_modules $out/lib/

    # --- Patch main.js to force packaged mode ---
    # 1. Set ELECTRON_IS_DEV early to "0"
    sed -i '1i process.env.ELECTRON_IS_DEV = "0";' $out/lib/numara/electron/main.js

    # 2. Override the app.isPackaged check to always be true
    #    (preserve the rest of the line, just change the condition)
    sed -i 's/if (!app.isPackaged)/if (false)/g' $out/lib/numara/electron/main.js

    # Make main script executable
    chmod +x $out/lib/numara/electron/main.js

    # Create wrapper with production environment flags
    makeWrapper ${electron}/bin/electron $out/bin/numara \
      --add-flags "$out/lib/numara/electron/main.js" \
      --set NODE_ENV production \
      --set ELECTRON_IS_DEV 0 \
      --set APPIMAGE 1 \
      --set ELECTRON_DISABLE_SECURITY_WARNINGS 1   # silences CSP warning as well

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "numara";
      desktopName = "Numara";
      comment = "Simple notepad calculator built on Electron, powered by Math.js";
      genericName = "Calculator";
      exec = "numara %U";
      icon = "numara";
      startupNotify = true;
      categories = [ "Utility" "Calculator" ];
      mimeTypes = [ "x-scheme-handler/numara" ];
    })
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Simple notepad calculator built on Electron, powered by Math.js";
    homepage = "https://github.com/bornova/numara-calculator";
    changelog = "https://github.com/bornova/numara-calculator/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ your-github-handle ];
    mainProgram = "numara";
    platforms = electron.meta.platforms;
  };
}
