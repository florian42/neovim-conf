# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Configuration Architecture

This is a modern Neovim configuration built with Lua using the Lazy.nvim plugin manager. The configuration follows a modular architecture with clear separation of concerns:

- **Entry Point**: `init.lua` bootstraps the configuration by loading modules in sequence
- **Plugin Management**: Lazy.nvim with 33 plugins, all versions pinned in `lazy-lock.json`
- **Configuration Structure**: Modular specs in `lua/plugins/` and `lua/plugins/lang/` directories
- **Core Modules**: `options.lua`, `keymaps.lua`, `commands.lua`, and `config/` directory

## Key Configuration Files

- `lua/options.lua` - Comprehensive Vim settings and modern defaults
- `lua/keymaps.lua` - Global key mappings (leader: `<Space>`)
- `lua/config/autocmds.lua` - Autocommands and event handlers
- `lua/config/lazy.lua` - Plugin manager bootstrap and configuration
- `lua/plugins/lsp.lua` - Language Server Protocol setup with Mason.nvim
- `lua/plugins/formatting.lua` - Code formatting via Conform.nvim
- `lua/plugins/editor.lua` - Editor enhancements (Which-key, Snacks, Mini.nvim)
- `lua/plugins/filesystem.lua` - Oil.nvim file explorer configuration

## Language Support

The configuration supports multiple languages with intelligent project detection:

- **Lua**: lua_ls, stylua formatting, lazydev.nvim for development
- **JavaScript/TypeScript**: typescript-tools.nvim, Deno support, prettier formatting
- **Python**: black formatting, comprehensive snippets
- **Go**: gopls LSP, gofmt formatting
- **OCaml**: ocamllsp support
- **YAML**: yamlls with CloudFormation schema integration

**Important**: The config automatically detects Deno vs TypeScript projects and disables conflicting language servers accordingly.

## Plugin Management Commands

```bash
# Start Neovim (triggers lazy loading)
nvim

# Plugin management (within Neovim)
:Lazy                 # Open plugin manager
:Lazy sync            # Update all plugins
:Lazy clean           # Remove unused plugins
:Lazy profile         # Performance profiling
```

## LSP and Development Tools

```bash
# LSP server management (within Neovim)
:Mason                # Manage LSP servers, formatters, linters
:LspInfo              # Show LSP status for current buffer
:ConformInfo          # Show available formatters

# Key mappings for development
<leader>ca            # Code actions
<leader>cr            # Rename symbol
gd                    # Go to definition
gr                    # Go to references
K                     # Hover documentation
```

## Custom Features

- **InsertToday** command: Inserts current date in ISO format
- **Oil.nvim**: File explorer with LSP integration and custom keymaps for splits
- **Harpoon**: Quick file navigation system
- **Dark-notify**: Automatic theme switching based on system dark mode
- **Blink.cmp**: Modern completion engine replacing nvim-cmp
- **Which-key**: Command palette with Helix preset for discoverability

## Configuration Maintenance

When modifying the configuration:

1. **Plugin Changes**: Edit appropriate files in `lua/plugins/` or `lua/plugins/lang/`
2. **Key Mappings**: Modify `lua/keymaps.lua` for global mappings or plugin-specific files
3. **LSP Configuration**: Update `lua/plugins/lsp.lua` and language-specific files
4. **Formatting**: Configure formatters in `lua/plugins/formatting.lua`

The configuration uses lazy loading extensively - plugins are loaded based on events, commands, or filetypes to optimize startup performance.

## Snippets

Custom snippets are available in the `snippets/` directory for:
- Markdown, Python, TypeScript, React-TypeScript, Package.json

Snippets follow VSCode snippet format and are integrated via the completion system.