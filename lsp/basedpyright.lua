-- Workaround: basedpyright (and pyright) sometimes return rename WorkspaceEdits
-- with `annotationId` on per-edit items but no top-level `changeAnnotations`
-- map. That violates the LSP spec, and Neovim 0.12 hard-asserts on it in
-- vim.lsp.util.apply_text_edits ("change_annotations must be provided for
-- annotated text edits"), aborting the rename.
--
-- Upstream context:
--   - neovim/neovim#34731: closed as a server bug; nvim won't relax the assert.
--   - DetachHead/basedpyright#1352: merged 2025-06-28, but only fixes ONE call
--     site in workspaceEditUtils.ts. Other paths (cross-file renames, certain
--     import rewrites) still emit orphan annotationIds — confirmed against
--     basedpyright 1.38.3.
--
-- Strip orphan annotationIds before the default rename handler runs.
--
-- Remove this when EITHER of the following is true:
--   1. basedpyright fully fixes its rename output. Test by deleting the
--      `handlers` block, restarting nvim, opening a file in this project, and
--      renaming a symbol that is imported from another module — if it succeeds
--      without the "change_annotations must be provided" assert, the
--      workaround is no longer needed.
--   2. Neovim downgrades the assert to a warning / fills in a default
--      annotations map. Watch neovim/neovim#34731 and the apply_text_edits
--      logic in runtime/lua/vim/lsp/util.lua around the `text_edit.annotationId`
--      branch.
local function strip_orphan_annotations(workspace_edit)
  if not workspace_edit then return end
  if workspace_edit.changeAnnotations then return end
  local function clean(edits)
    if not edits then return end
    for _, e in ipairs(edits) do
      e.annotationId = nil
    end
  end
  if workspace_edit.documentChanges then
    for _, change in ipairs(workspace_edit.documentChanges) do
      clean(change.edits)
    end
  end
  if workspace_edit.changes then
    for _, edits in pairs(workspace_edit.changes) do
      clean(edits)
    end
  end
end

return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "pyrightconfig.json",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  },
  handlers = {
    ["textDocument/rename"] = function(err, result, ctx, config)
      strip_orphan_annotations(result)
      return vim.lsp.handlers["textDocument/rename"](err, result, ctx, config)
    end,
  },
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "strict",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        diagnosticSeverityOverrides = {
          reportUnannotatedClassAttribute = "none",
          reportUnknownMemberType = "none",
          reportUnknownVariableType = "none",
        },
      },
    },
  },
}
