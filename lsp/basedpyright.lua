return {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = 'strict',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        diagnosticSeverityOverrides = {
          reportUnannotatedClassAttribute = 'none',
          reportUnknownMemberType = 'none',
          reportUnknownVariableType = 'none',
        },
      },
    },
  },
}
