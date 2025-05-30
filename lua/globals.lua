-- Prevent Netrw (default file tree) from showing up at beginning
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.o.winborder = 'rounded'

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  group = highlight_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank()
  end,
})
