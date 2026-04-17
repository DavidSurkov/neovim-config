-- LSP Plugins
return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
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
    config = function()
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

          if not vim.b[bufnr].lsp_base_keymaps_set then
            -- Execute a code action, usually your cursor needs to be on top of an error
            -- or a suggestion from your LSP for this to activate.
            map('<leader>ca', require('fzf-lua').lsp_code_actions, 'Code Action', { 'n', 'x' })
            map('<leader>cr', vim.lsp.buf.rename, 'LSP Rename', { 'n', 'x' })

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
            map('<leader>cD', function()
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

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if
            client
            and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint)
            and not vim.b[bufnr].inlay_hint_toggle_set
          then
            map('<leader>th', function()
              local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, 'Toggle Inlay Hints')
            vim.b[bufnr].inlay_hint_toggle_set = true
          end
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

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- pyright = {},
        eslint = {
          settings = {
            workingDirectory = {
              mode = 'auto',
            },
          },
          on_attach = function(client)
            -- Keep Prettier as the formatter for JS/TS.
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        },
        vtsls = {
          root_dir = function(fname)
            local util = require 'lspconfig.util'
            local root = util.root_pattern('pnpm-workspace.yaml', 'package.json', 'tsconfig.json', '.git')(fname)
            if root and root:find('/node_modules', 1, true) then
              return nil
            end
            return root
          end,
          filetypes = {
            'javascript',
            'javascriptreact',
            'javascript.jsx',
            'typescript',
            'typescriptreact',
            'typescript.tsx',
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'all' },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = true },
              },
            },
          },
          on_attach = function(client, _)
            -- Work around intermittent tsserver 5.9.x foldingRange crashes ("length < 0").
            client.server_capabilities.foldingRangeProvider = false

            client.commands['_typescript.moveToFileRefactoring'] = function(command, _)
              local action, uri, range = unpack(command.arguments)

              local function move(newf)
                client.request('workspace/executeCommand', {
                  command = command.command,
                  arguments = { action, uri, range, newf },
                })
              end

              local fname = vim.uri_to_fname(uri)
              client.request('workspace/executeCommand', {
                command = 'typescript.tsserverRequest',
                arguments = {
                  'getMoveToRefactoringFileSuggestions',
                  {
                    file = fname,
                    startLine = range.start.line + 1,
                    startOffset = range.start.character + 1,
                    endLine = range['end'].line + 1,
                    endOffset = range['end'].character + 1,
                  },
                },
              }, function(_, result)
                local files = result.body.files
                table.insert(files, 1, 'Enter new path...')
                vim.ui.select(files, {
                  prompt = 'Select move destination:',
                  format_item = function(f)
                    return vim.fn.fnamemodify(f, ':~:.')
                  end,
                }, function(f)
                  if f and f:find '^Enter new path' then
                    vim.ui.input({
                      prompt = 'Enter move destination:',
                      default = vim.fn.fnamemodify(fname, ':h') .. '/',
                      completion = 'file',
                    }, function(newf)
                      if newf then
                        move(newf)
                      end
                    end)
                  elseif f then
                    move(f)
                  end
                end)
              end)
            end
          end,
        },
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
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        -- ts_ls = {},
        --

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }
      -- apply same settings for js as ts
      servers.vtsls.settings.javascript =
        vim.tbl_deep_extend('force', {}, servers.vtsls.settings.typescript, servers.vtsls.settings.javascript or {})

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
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        -- 'astro-language-server',
        'biome',
        'css-lsp',
        -- 'debugpy',
        -- 'delve',
        'docker-compose-language-service',
        'dockerfile-language-server',
        'eslint-lsp',
        'hadolint',
        -- 'intelephense',
        'js-debug-adapter',
        'lua-language-server',
        'neocmakelsp',
        -- 'php-cs-fixer',
        -- 'php-debug-adapter',
        -- 'phpcs',
        -- 'pint',
        'prettier',
        'pyright',
        -- 'ruff',
        'stylua',
        'tailwindcss-language-server',
        'vtsls',
      })
      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
