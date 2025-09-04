-- Basic mappings
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic mappings
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Tab mappings
vim.keymap.set('n', '<leader>tn', ':tabnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tp', ':tabprevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tf', ':tabfirst<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tl', ':tablast<CR>', { noremap = true, silent = true })

--Neotree
vim.keymap.set('n', '<leader>nr', ':Neotree reveal<CR>', { desc = 'Reveal current file in Neo-tree' })

--Autoformat
-- Toggle autoformat for the current buffer
vim.keymap.set('n', '<leader>uf', function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
  print('Autoformat ' .. (vim.b.disable_autoformat and 'disabled' or 'enabled'))
end, { desc = 'Toggle autoformat' })

-- Format selected lines using conform.nvim
vim.keymap.set('v', '<leader>cf', function()
  require('conform').format {
    async = true,
    lsp_fallback = true,
  }
end, { desc = 'Format selection' })
