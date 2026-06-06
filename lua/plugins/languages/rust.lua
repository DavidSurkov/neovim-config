return {
  {
    'rust-lang/rust.vim',
    ft = 'rust',
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        rust_analyzer = {
          settings = {
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
              },
              check = {
                command = 'clippy',
              },
              procMacro = {
                enable = true,
              },
              inlayHints = {
                bindingModeHints = { enable = true },
                closingBraceHints = { enable = true },
                closureCaptureHints = { enable = true },
                closureReturnTypeHints = { enable = 'always' },
                lifetimeElisionHints = { enable = 'always', useParameterNames = true },
                typeHints = { enable = true },
              },
            },
          },
        },
      },
    },
  },
}
