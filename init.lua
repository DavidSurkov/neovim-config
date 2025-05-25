-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- Load plugins (which will use lazy.nvim)
require("plugins")

-- Load core modules
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Load Mason setup first if it's in its own module or directly in the lsp module.
-- For instance, if your lsp.lua starts with:
require('mason').setup()
-- require('mason-lspconfig').setup({automatic_installation = true})

-- Load additional configuration for specific plugins
require("config.telescope")
require("config.treesitter")
require("config.lsp")

-- Optionally load custom plugins (overrides or additional plugins)
require("custom.plugins")
