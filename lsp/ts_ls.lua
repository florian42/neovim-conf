return {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json' },
  single_file_support = false,
  settings = {
    typescript = {
      preferences = {
        importModuleSpecifierPreference = 'non-relative',
      },
    },
  },
}
