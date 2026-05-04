{ pkgs, ... }:

{
  packages = [ pkgs.flutter ];

  enterShell = ''
    flutter --version
  '';
}
