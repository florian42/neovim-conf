return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  -- go.work first: in a multi-module workspace the workspace root is the
  -- correct root, not whichever go.mod happens to be nearest the buffer.
  root_markers = { "go.work", "go.mod", ".git" },
}
