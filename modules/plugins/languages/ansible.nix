{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.types) enum;
  inherit (lib.nvim.types) mkGrammarOption deprecatedSingleOrListOf;
  inherit (lib.nvim.attrsets) mapListToAttrs;

  cfg = config.vim.languages.ansible;

  defaultServers = ["ansible-language-server"];
  servers = {
    ansible-language-server = {
      enable = true;
      cmd = ["ansible-language-server" "--stdio"];
      filetypes = ["yaml.ansible"];
      root_markers = [".git" "ansible.cfg"];
    };
  };
in {
  options.vim.languages.ansible = {
    enable = mkEnableOption "Ansible language support";

    treesitter = {
      enable = mkEnableOption "YAML treesitter" // {default = config.vim.languages.enableTreesitter;};
      package = mkGrammarOption pkgs "yaml";
    };

    lsp = {
      enable = mkEnableOption "Ansible LSP support" // {default = config.vim.lsp.enable;};
      servers = mkOption {
        type = deprecatedSingleOrListOf "vim.language.ansible.lsp.servers" (enum (attrNames servers));
        default = defaultServers;
        description = "Ansible LSP server to use";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.package];
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.servers =
        mapListToAttrs (n: {
          name = n;
          value = servers.${n};
        })
        cfg.lsp.servers;
    })
  ]);
}
