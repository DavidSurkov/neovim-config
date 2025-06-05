return {
  {
    'folke/snacks.nvim',
    ---@type snacks.Config
    opts = {
      -- vim.input
      input = {
        -- your input configuration comes here
        -- or leave it empty to use the default settings
      },
      indent = {},

      ---@class snacks.lazygit.Config: snacks.terminal.Opts
      ---@field args? string[]
      ---@field theme? snacks.lazygit.Theme
      lazygit = {},
    },
    keys = {
      {
        '<leader>gg',
        function()
          require('snacks').lazygit()
        end,
        desc = 'LazyGit',
      },
    },
    cmd = { 'LazyGit' },
    config = function()
      vim.api.nvim_create_user_command('LazyGit', function()
        require('snacks').lazygit()
      end, {})
    end,
  },
}
