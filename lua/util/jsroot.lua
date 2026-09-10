-- Mutual exclusion between `denols` and `ts_ls`.
--
-- Both servers claim javascript/javascriptreact/typescript/typescriptreact.
-- nvim-lspconfig used to arbitrate between them; native `vim.lsp.enable()`
-- does not, and plain `root_markers` cannot express "attach only if the other
-- one does not". Worse, a config with neither `root_dir` nor `workspace_required`
-- starts anyway with `root_dir = nil` (see `vim.lsp.enable` in
-- runtime/lua/vim/lsp.lua), so a stray .ts file outside any project would
-- attach BOTH clients and produce duplicate diagnostics and completions.
--
-- Rule: walk up from the buffer for the nearest Deno marker and the nearest
-- Node marker. Whichever is deeper (closer to the file) owns the buffer. A
-- directory holding both is treated as Deno, since a Deno project commonly
-- carries a tsconfig.json just for editor tooling.

local M = {}

local DENO_MARKERS = { "deno.json", "deno.jsonc", "deno.lock" }
local NODE_MARKERS = { "package.json", "tsconfig.json", "jsconfig.json" }

--- Number of path segments, or -1 when no root was found, so that "not found"
--- always loses a depth comparison.
--- @param path string|nil
--- @return integer
local function depth(path)
  if not path then return -1 end
  return #vim.split(path, "/", { plain = true })
end

--- @param bufnr integer
--- @return string|nil deno_root, string|nil node_root
local function roots(bufnr) return vim.fs.root(bufnr, DENO_MARKERS), vim.fs.root(bufnr, NODE_MARKERS) end

--- `root_dir` for denols: attach only when Deno owns this buffer.
--- @param bufnr integer
--- @param on_dir fun(root_dir?: string)
function M.deno(bufnr, on_dir)
  local deno, node = roots(bufnr)
  if deno and depth(deno) >= depth(node) then on_dir(deno) end
end

--- `root_dir` for ts_ls: attach only when Deno does not own this buffer.
--- @param bufnr integer
--- @param on_dir fun(root_dir?: string)
function M.node(bufnr, on_dir)
  local deno, node = roots(bufnr)
  if node and depth(node) > depth(deno) then on_dir(node) end
end

return M
