-- vue_ls 3.x runs in "hybrid mode": it does not do TypeScript analysis itself.
-- It sends `tsserver/request` notifications that must be forwarded to the
-- TypeScript server as a `typescript.tsserverRequest` command, and the reply
-- handed back as `tsserver/response`. nvim-lspconfig used to install this
-- bridge; with native vim.lsp.enable we have to do it ourselves, otherwise
-- vue_ls attaches but returns nothing for anything type-related.
--
-- The other half of the bridge is @vue/typescript-plugin, registered in
-- lsp/ts_ls.lua.
return {
  cmd = { "vue-language-server", "--stdio" },
  filetypes = { "vue" },
  root_markers = { "package.json" },
  on_init = function(client)
    client.handlers["tsserver/request"] = function(_, result, context)
      local ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })
      if #ts_clients == 0 then
        vim.notify(
          "vue_ls: no ts_ls client attached to this buffer; Vue type features are unavailable.",
          vim.log.levels.ERROR
        )
        return
      end
      local ts_client = ts_clients[1]

      local id, command, payload = unpack(result[1])
      ts_client:exec_cmd({
        command = "typescript.tsserverRequest",
        arguments = { command, payload },
      }, { bufnr = context.bufnr }, function(_, r) client:notify("tsserver/response", { { id, r and r.body } }) end)
    end
  end,
}
