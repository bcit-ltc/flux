{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    kubectl
    fluxcd
    kubectx
    kustomize
    git
    jq
    vault
    nixd
  ];
}
