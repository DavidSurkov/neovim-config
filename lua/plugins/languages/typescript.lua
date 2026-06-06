return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
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
          root_dir = function(bufnr, on_dir)
            local util = require 'lspconfig.util'
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local root = util.root_pattern('pnpm-workspace.yaml', 'package.json', 'tsconfig.json', '.git')(fname)
            if root and root:find('/node_modules', 1, true) then
              return
            end
            on_dir(root)
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
            javascript = {},
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
      },
      setup = {
        vtsls = function(_, opts)
          opts.settings.javascript =
            vim.tbl_deep_extend('force', {}, opts.settings.typescript, opts.settings.javascript or {})

          if vim.g.vtsls_inlay_hint_padding_patch then
            return
          end

          local method = vim.lsp.protocol.Methods.textDocument_inlayHint
          local default_handler = vim.lsp.handlers[method]

          vim.lsp.handlers[method] = function(err, result, ctx, config)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if client and client.name == 'vtsls' and type(result) == 'table' then
              for _, hint in ipairs(result) do
                if hint.kind == 1 then
                  hint.paddingLeft = false
                end
              end
            end

            return default_handler(err, result, ctx, config)
          end
          vim.g.vtsls_inlay_hint_padding_patch = true
        end,
      },
      tools = {
        ['eslint-lsp'] = true,
        vtsls = true,
      },
    },
  },
  -- attempt to enable debugger
  {
    'mfussenegger/nvim-dap',
    optional = true,
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, 'js-debug-adapter')
        end,
      },
    },
    opts = function()
      local dap = require 'dap'
      if not dap.adapters['pwa-node'] then
        require('dap').adapters['pwa-node'] = {
          type = 'server',
          host = 'localhost',
          port = '${port}',
          executable = {
            command = 'node',
            args = {
              vim.env.MASON .. '/packages/' .. 'js-debug-adapter' .. '/js-debug/src/dapDebugServer.js',
              '${port}',
            },
          },
        }
      end
      if not dap.adapters['node'] then
        dap.adapters['node'] = function(cb, config)
          if config.type == 'node' then
            config.type = 'pwa-node'
          end
          local nativeAdapter = dap.adapters['pwa-node']
          if type(nativeAdapter) == 'function' then
            nativeAdapter(cb, config)
          else
            cb(nativeAdapter)
          end
        end
      end

      local js_filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }

      local vscode = require 'dap.ext.vscode'
      vscode.type_to_filetypes['node'] = js_filetypes
      vscode.type_to_filetypes['pwa-node'] = js_filetypes

      for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
          dap.configurations[language] = {
            {
              type = 'pwa-node',
              request = 'launch',
              name = 'Launch file',
              program = '${file}',
              cwd = '${workspaceFolder}',
            },
            {
              type = 'pwa-node',
              request = 'attach',
              name = 'Attach',
              processId = require('dap.utils').pick_process,
              cwd = '${workspaceFolder}',
            },
          }
        end
      end
    end,
  },

  -- Filetype icons
  {
    'echasnovski/mini.icons',
    opts = {
      file = {
        ['.eslintrc.js'] = { glyph = '󰱺', hl = 'MiniIconsYellow' },
        ['.node-version'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['.prettierrc'] = { glyph = '', hl = 'MiniIconsPurple' },
        ['.yarnrc.yml'] = { glyph = '', hl = 'MiniIconsBlue' },
        ['eslint.config.js'] = { glyph = '󰱺', hl = 'MiniIconsYellow' },
        ['package.json'] = { glyph = '', hl = 'MiniIconsGreen' },
        ['tsconfig.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        ['tsconfig.build.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        ['yarn.lock'] = { glyph = '', hl = 'MiniIconsBlue' },
      },
    },
  },
}
