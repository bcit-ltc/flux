{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    kubectl
    fluxcd
    kubectx
    kustomize
    krew
    git
    jq
    vault
    nixd
  ];
}
