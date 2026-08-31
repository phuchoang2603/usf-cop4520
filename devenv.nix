{ pkgs, ... }:

{
  packages = [
    pkgs.gcc
  ];

  languages.cplusplus = {
    enable = true;
    lsp = {
      enable = true;
      package = pkgs.clang-tools;
    };
  };

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
}
