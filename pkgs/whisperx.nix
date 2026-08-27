{ lib
, stdenv
, fetchFromGitHub
, python3
, cudaSupport ? true
}:

let
  buildPythonPackage = python3.pkgs.buildPythonPackage;

  # 1. Enable CUDA in PyTorch
  torch = python3.pkgs.torch.override {
    inherit cudaSupport;
  };

  # 2. Build torchaudio and torchvision with that CUDA-enabled torch
  torchaudio = python3.pkgs.torchaudio.override { torch = torch; };
  torchvision = python3.pkgs.torchvision.override { torch = torch; };

  # 3. Enable CUDA in ctranslate2 – the correct argument name is `withCUDA`
  ctranslate2 = python3.pkgs.ctranslate2.override {
    withCUDA = cudaSupport;
  };

  # 4. Pass the CUDA-enabled ctranslate2 to faster-whisper
  faster-whisper = python3.pkgs.faster-whisper.override {
    inherit ctranslate2;
  };

in
buildPythonPackage rec {
  pname = "whisperx";
  version = "3.8.7rc1";

  src = fetchFromGitHub {
    owner = "m-bain";
    repo = "whisperX";
    rev = "v${version}";
    # REPLACE the hash below with the output of:
    # nix-prefetch-url --unpack https://github.com/m-bain/whisperX/archive/v3.8.7rc1.tar.gz
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  pyproject = true;

  propagatedBuildInputs = [
    ctranslate2
    faster-whisper
    python3.pkgs.nltk
    python3.pkgs.numpy
    python3.pkgs.omegaconf
    python3.pkgs.pandas
    python3.pkgs.pyannote-audio
    python3.pkgs.huggingface-hub
    torch
    torchaudio
    torchvision
    python3.pkgs.transformers
  ] ++ lib.optionals (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64) [
    python3.pkgs.triton
  ];

  # Fix PyTorch 2.6+ weights_only issue for pyannote models
  postPatch = ''
    find . -name "*.py" -exec sed -i 's/torch\.load(/torch.load(weights_only=False, /g' {} \;
  '';

  # Environment fallback for weights_only
  makeWrapperArgs = [
    "--set PYTORCH_WEIGHTS_ONLY 0"
  ];

  meta = with lib; {
    description = "Time-Accurate Automatic Speech Recognition using Whisper with word-level timestamps and speaker diarization";
    homepage = "https://github.com/m-bain/whisperX";
    license = licenses.bsd2;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
