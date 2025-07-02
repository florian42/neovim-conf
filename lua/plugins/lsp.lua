return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local util = require("lspconfig.util")
      require("lspconfig").lua_ls.setup({})
      require("lspconfig").ocamllsp.setup({})
      require("lspconfig").gopls.setup({})
      require("lspconfig").denols.setup({
        root_dir = util.root_pattern("deno.json", "deno.jsonc"),
      })
      require("lspconfig").yamlls.setup({
        settings = {
          yaml = {
            schemas = {
              ["https://s3.amazonaws.com/cfn-resource-specifications-us-east-1-prod/schemas/2.15.0/all-spec.json"] = "~/source/github.com/einwert/infrastructure",
            },
            customTags = {
              "!fn",
              "!And",
              "!If",
              "!Not",
              "!Equals",
              "!Or",
              "!FindInMap sequence",
              "!Base64",
              "!Cidr",
              "!Ref",
              "!Ref Scalar",
              "!Sub",
              "!Sub sequence",
              "!GetAtt",
              "!GetAZs",
              "!ImportValue",
              "!Select",
              "!Split",
              "!Join sequence",
            },
          },
        },
      })
      require("lspconfig").basedpyright.setup({
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
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
          end
        end,
      })
    end,
  },
  { "j-hui/fidget.nvim", opts = {} },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    enabled = true,
    config = function()
      vim.keymap.set(
        "n",
        "<leader>co",
        ":TSToolsRemoveUnusedImports<CR>",
        { noremap = true, silent = true, desc = "Remove unused imports" }
      )
      local util = require("lspconfig.util")
      require("typescript-tools").setup({
        settings = {
          expose_as_code_action = { "remove_unused_imports", "add_missing_imports" },
          tsserver_file_preferences = { importModuleSpecifierPreference = "non-relative" },
        },
        single_file_support = false,
        root_dir = util.root_pattern("tsconfig.json"),
      })
    end,
  },
  { -- Linting
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        typescriptreact = { "eslint" },
        javascriptreact = { "eslint" },
        typescript = { "eslint" },
        javascript = { "eslint" },
        yaml = { "cfn_lint" },
        python = { "flake8" },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
