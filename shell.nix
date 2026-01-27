{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    kubectl
    fluxcd
    kubectx
    kustomize
    git
    jq
    nixd
  ];

  shellHook = ''
    echo "Azure Infrastructure Development Environment"
    echo "Available tools:"
    echo "  - terraform $(terraform version | head -n1)"
    echo "  - az CLI $(az version --output tsv --query '"cli"')"
    echo ""
    echo "Run 'terraform init' to initialize the project"
    echo "Run 'az login' to authenticate with Azure"
  '';
}
