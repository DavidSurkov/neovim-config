return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
    },
    keys = {
      {
        '<leader>nr',
        ':Neotree reveal<CR>',
        desc = 'Reveal current file in Neo-tree',
      },
      {
        '<leader>nt',
        ':Neotree toggle<CR>',
        desc = 'Toggle Neotree',
      },
    },

    config = function()
      require('neo-tree').setup {
        hide_root_node = true, -- Hide the root node.
        source_selector = {
          winbar = true,
          statusline = false,
        },
      }
    end,
  },
}
