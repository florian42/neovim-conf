-- Note on filetypes: nvim's own filetype table maps .ml/.mli/.mll/.mly/.mlt
-- all to `ocaml` (runtime/lua/vim/filetype.lua). The separate `ocamlinterface`
-- / `ocamllex` / `menhir` filetypes only exist if you install ocaml/vim-ocaml,
-- which this config does not — listing them here just produced "Unknown
-- filetype" warnings in :checkhealth vim.lsp without ever matching.
return {
  cmd = { 'ocamllsp' },
  filetypes = { 'ocaml', 'dune' },
  -- vim.fs.root does not expand globs, so `*.opam` cannot be a marker here.
  root_markers = { 'dune-project', 'dune-workspace', 'esy.json', '.git' },
}
