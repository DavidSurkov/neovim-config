return {
  {
    'folke/snacks.nvim',
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- vim.input
      input = {
        -- your input configuration comes here
        -- or leave it empty to use the default settings
      },
      indent = {
        enabled = true,
        scope = {
          enabled = true,
          char = '│',
          only_current = false, -- set true if you only want the active window
        },
      },

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
    config = function(_, opts)
      require('snacks').setup(opts)
      vim.api.nvim_create_user_command('LazyGit', function()
        require('snacks').lazygit()
      end, {})
    end,
  },
}
