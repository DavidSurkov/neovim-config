-- LSP Plugins
return {
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },
    opts = {
      servers = {},
      setup = {},
      tools = {
        -- General tools that do not have a dedicated language module yet.
        biome = true,
        ['css-lsp'] = true,
        hadolint = true,
        ['js-debug-adapter'] = true,
        neocmakelsp = true,
        prettier = true,
        pyright = true,
        stylua = true,
      },
    },
    config = function(_, opts)
      opts = opts or {}
      local servers = opts.servers or {}

      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local bufnr = event.buf
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
          end
          local function apply_code_action(kind)
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { kind },
                diagnostics = vim.diagnostic.get(bufnr),
              },
              filter = function(action)
                return action.kind == kind or vim.startswith(action.kind or '', kind .. '.')
              end,
            }
          end
          local function is_enabled_code_action(action)
            return not action.disabled
          end

          if not vim.b[bufnr].lsp_base_keymaps_set then
            -- Execute a code action, usually your cursor needs to be on top of an error
            -- or a suggestion from your LSP for this to activate.
            map('<leader>ca', function()
              require('fzf-lua').lsp_code_actions {
                filter = is_enabled_code_action,
              }
            end, 'Code Action', { 'n', 'x' })
            map('<leader>cr', vim.lsp.buf.rename, 'LSP Rename', { 'n', 'x' })
            map('<leader>th', function()
              local method = vim.lsp.protocol.Methods.textDocument_inlayHint
              local supported = vim.iter(vim.lsp.get_clients { bufnr = bufnr }):any(function(attached_client)
                return attached_client:supports_method(method, bufnr)
              end)

              if not supported then
                vim.notify('No attached LSP supports inlay hints for this buffer', vim.log.levels.WARN)
                return
              end

              local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
              vim.notify('Inlay hints ' .. (enabled and 'disabled' or 'enabled'))
            end, 'Toggle Inlay Hints')

            -- WARN: This is not Goto Definition, this is Goto Declaration.
            --  For example, in C this would take you to the header.
            map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
            vim.b[bufnr].lsp_base_keymaps_set = true
          end

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == 'eslint' then
            map('<leader>cE', function()
              vim.lsp.buf.code_action {
                apply = true,
                context = {
                  only = { 'source.fixAll.eslint' },
                  diagnostics = {},
                },
              }
            end, 'ESLint Fix All')
            map('<leader>uE', function()
              local bufnr = event.buf
              if vim.lsp.buf_is_attached(bufnr, client.id) then
                vim.lsp.buf_detach_client(bufnr, client.id)
                vim.notify 'ESLint disabled for current buffer'
              else
                vim.lsp.buf_attach_client(bufnr, client.id)
                vim.notify 'ESLint enabled for current buffer'
              end
            end, 'Toggle ESLint (Buffer)')
          end
          if client and client.name == 'vtsls' and not vim.b[bufnr].vtsls_keymaps_set then
            map('gD', function()
              local position_params = vim.lsp.util.make_position_params()
              local params = {
                command = 'typescript.goToSourceDefinition',
                arguments = { position_params.textDocument.uri, position_params.position },
              }
              require('trouble').open {
                mode = 'lsp_command',
                params = params,
              }
            end, 'Goto Source Definition')
            map('gR', function()
              local params = {
                command = 'typescript.findAllFileReferences',
                arguments = { vim.uri_from_bufnr(event.buf) },
              }
              require('trouble').open {
                mode = 'lsp_command',
                params = params,
              }
            end, 'File References')
            map('<leader>co', function()
              apply_code_action 'source.organizeImports'
            end, 'Organize Imports')
            map('<leader>cM', function()
              apply_code_action 'source.addMissingImports.ts'
            end, 'Add Missing Imports')
            map('<leader>cu', function()
              apply_code_action 'source.removeUnusedImports'
            end, 'Remove Unused Imports')
            map('<leader>cF', function()
              apply_code_action 'source.fixAll.ts'
            end, 'Fix All Diagnostics')
            map('<leader>cV', function()
              vim.notify('TypeScript version selection is not wired into this Neovim config', vim.log.levels.WARN)
            end, 'Select TS Workspace Version')
            vim.b[bufnr].vtsls_keymaps_set = true
          end
          -- if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          --   local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          --   vim.api.nvim_create_autocmd({ 'CursorHold' }, {
          --     buffer = event.buf,
          --     group = highlight_augroup,
          --     callback = vim.lsp.buf.document_highlight,
          --   })
          --
          --   vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
          --     buffer = event.buf,
          --     group = highlight_augroup,
          --     callback = vim.lsp.buf.clear_references,
          --   })
          --
          --   vim.api.nvim_create_autocmd('LspDetach', {
          --     group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          --     callback = function(event2)
          --       vim.lsp.buf.clear_references()
          --       vim.api.nvim_clear_autocmds {
          --         group = 'kickstart-lsp-highlight',
          --         buffer = event2.buf,
          --       }
          --     end,
          --   })
          -- end
        end,
      })

      -- Change diagnostic symbols in the sign column (gutter)
      -- if vim.g.have_nerd_font then
      --   local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
      --   local diagnostic_signs = {}
      --   for type, icon in pairs(signs) do
      --     diagnostic_signs[vim.diagnostic.severity[type]] = icon
      --   end
      --   vim.diagnostic.config { signs = { text = diagnostic_signs } }
      -- end

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Folding capabilities required by ufo.nvim
      -- capabilities.textDocument.foldingRange = {
      --   dynamicRegistration = false,
      --   lineFoldingOnly = true,
      -- }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = {}
      for _, tool in ipairs(vim.tbl_keys(servers)) do
        ensure_installed[tool] = true
      end
      for _, tool in ipairs(vim.tbl_keys(opts.tools or {})) do
        ensure_installed[tool] = true
      end
      for _, tool in ipairs(opts.ensure_installed or {}) do
        ensure_installed[tool] = true
      end

      require('mason-tool-installer').setup {
        ensure_installed = vim.tbl_keys(ensure_installed),
      }

      require('mason-lspconfig').setup {
        automatic_enable = false,
      }

      for server_name, server in pairs(servers) do
        -- mason-lspconfig v2 removed handlers; configure servers directly.
        local setup = opts.setup and opts.setup[server_name]
        if setup then
          setup(server_name, server)
        end

        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(server_name, server)
        vim.lsp.enable(server_name)
      end
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
