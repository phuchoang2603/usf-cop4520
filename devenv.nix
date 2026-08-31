{ pkgs, lib, ... }:

let
  cudaPkgs = pkgs.cudaPackages;
  # nvcc lags system GCC; 13 is a safe host compiler for current CUDA toolkits.
  nvccHostCc = pkgs.gcc13;
in
{
  packages = [
    pkgs.gcc
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    nvccHostCc
    cudaPkgs.cuda_nvcc
    cudaPkgs.cuda_cudart
    cudaPkgs.cccl
    cudaPkgs.cuda_gdb
  ];

  languages.cplusplus = {
    enable = true;
    lsp = {
      enable = true;
      package = pkgs.clang-tools;
    };
  };

  env = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    CUDAARCHS = "75";
    NVCC_PREPEND_FLAGS = "-ccbin ${nvccHostCc}/bin";
  };

  enterShell = lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  scripts.cpprun.exec = ''
    if [ -z "$1" ]; then
      echo "Usage: cpprun <file.cpp>"
      exit 1
    fi
    file="$1"
    base="''${file%.*}"
    echo "--- Compiling $file ---"

    g++ -Wall -Wextra -std=c++20 -O2 "$file" -o "$base" && {
      echo "--- Running $base ---"
      ./"$base"
      rm -f "$base"
    } || {
      echo "--- Compilation Failed ---"
      exit 1
    }
  '';

  scripts.nvccrun.exec = ''
    if [ -z "$1" ]; then
      echo "Usage: nvccrun <file.cu>"
      exit 1
    fi
    file="$1"
    base="''${file%.*}"
    echo "--- Compiling $file ---"

    nvcc -O2 -arch=sm_75 "$file" -o "$base" && {
      echo "--- Running $base ---"
      ./"$base"
      rm -f "$base"
    } || {
      echo "--- Compilation Failed ---"
      exit 1
    }
  '';
}
