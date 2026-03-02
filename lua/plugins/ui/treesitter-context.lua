-- Show context of the current function
return {
  'nvim-treesitter/nvim-treesitter-context',
  event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
  opts = function()
    local tsc = require 'treesitter-context'

    vim.keymap.set('n', '<leader>ut', function()
      if tsc.enabled then
        tsc.disable()
      else
        tsc.enable()
      end
    end, { silent = true, desc = 'Toggle Treesitter Context' })

    return { mode = 'cursor', max_lines = 3 }
  end,
}
