{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;

mkShell.override { stdenv = gccStdenv; } {
  packages = [
    pkgsCross.x86_64-embedded.gcc
    pkgsCross.x86_64-embedded.binutils
    nasm
  ];
}
