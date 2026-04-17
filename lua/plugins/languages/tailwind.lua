return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        tailwindcss = {
          -- exclude a filetype from the default_config
          filetypes_exclude = {},
          -- add additional filetypes to the default_config
          filetypes_include = { 'javascript', 'typescript' },
          -- to fully override the default_config, change the below
          filetypes = { 'javascriptreact', 'typescriptreact', 'html', 'css', 'scss', 'sass' },
        },
      },
      setup = {
        tailwindcss = function(_, opts)
          local tw = require 'lspconfig.server_configurations.tailwindcss'

          opts.filetypes = vim.deepcopy(opts.filetypes or {})

          -- Treat an explicit filetypes list as an override.
          if #opts.filetypes == 0 then
            vim.list_extend(opts.filetypes, tw.default_config.filetypes)
          end

          -- Remove excluded filetypes
          --- @param ft string
          opts.filetypes = vim.tbl_filter(function(ft)
            return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
          end, opts.filetypes)

          -- Additional settings for Phoenix projects
          opts.settings = vim.tbl_deep_extend('force', opts.settings or {}, {
            tailwindCSS = {
              includeLanguages = {
                elixir = 'html-eex',
                eelixir = 'html-eex',
                heex = 'html-eex',
              },
            },
          })

          -- Add additional filetypes
          vim.list_extend(opts.filetypes, opts.filetypes_include or {})
          opts.filetypes = vim.fn.uniq(opts.filetypes)
        end,
      },
    },
  },
}
