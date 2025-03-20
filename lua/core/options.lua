-- core/options.lua: General settings

vim.o.hlsearch = false             -- Don't highlight searches
vim.wo.number = true               -- Show line numbers
vim.o.mouse = 'a'                  -- Enable mouse mode
vim.o.clipboard = 'unnamedplus'    -- Sync system clipboard
vim.o.termguicolors = true         -- Enable 24-bit colors
vim.o.breakindent = true           -- Enable break indent
vim.o.undofile = true              -- Enable persistent undo
vim.o.ignorecase = true            -- Case-insensitive searching
vim.o.smartcase = true             -- Case-sensitive if uppercase present
vim.wo.signcolumn = 'yes'          -- Always show sign column
vim.o.updatetime = 250             -- Faster completion
vim.o.timeoutlen = 300             -- Time to wait for a mapped sequence
vim.o.completeopt = 'menuone,noselect'
vim.opt.guifont = "MesloLGS Nerd Font Mono:h12"
