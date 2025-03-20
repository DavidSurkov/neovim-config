-- core/keymaps.lua: Key mapping definitions

-- Basic mappings
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic mappings
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Tab mappings
vim.keymap.set('n', '<leader>tn', ':tabnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tp', ':tabprevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tf', ':tabfirst<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tl', ':tablast<CR>', { noremap = true, silent = true })
