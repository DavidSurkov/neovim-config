return {
  {
    -- `lazydev` configures Lua LSP for the Neovim runtime and plugin APIs.
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      },
      tools = {
        ['lua-language-server'] = true,
      },
    },
  },
}
