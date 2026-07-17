local function select_server(server)
  return function(bufnr, on_dir)
    local util = require 'lspconfig.util'
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = util.root_pattern('pnpm-lock.yaml', 'package-lock.json', 'yarn.lock', 'bun.lock', 'bun.lockb', '.git')(
      fname
    ) or util.root_pattern('package.json', 'tsconfig.json')(fname)
    if not root then
      return
    end

    local package_path = vim.fs.joinpath(root, 'node_modules', 'typescript', 'package.json')
    local ok, package = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(package_path), '\n'))
    end)
    local major = ok
        and type(package) == 'table'
        and type(package.version) == 'string'
        and tonumber(package.version:match '^%d+')
      or nil
    local use_tsgo = major == nil or major >= 7
    if (server == 'tsgo') == use_tsgo then
      on_dir(root)
    end
  end
end

local inlay_hints = {
  enumMemberValues = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  parameterNames = { enabled = 'all' },
  parameterTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  variableTypes = { enabled = true },
}

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
        tsgo = {
          root_dir = select_server 'tsgo',
          cmd = function(dispatchers, config)
            local tsc = vim.fs.joinpath(config.root_dir, 'node_modules', '.bin', 'tsc')
            local cmd = vim.fn.executable(tsc) == 1 and tsc or 'tsgo'
            return vim.lsp.rpc.start({ cmd, '--lsp', '--stdio' }, dispatchers)
          end,
          settings = {
            typescript = {
              inlayHints = inlay_hints,
            },
          },
        },
        vtsls = {
          root_dir = select_server 'vtsls',
          settings = {
            vtsls = {
              autoUseWorkspaceTsdk = true,
            },
            typescript = {
              inlayHints = inlay_hints,
            },
            javascript = {
              inlayHints = inlay_hints,
            },
          },
          on_attach = function(client)
            -- Keep Prettier as the formatter for JS/TS.
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        },
      },
      tools = {
        ['eslint-lsp'] = true,
        tsgo = true,
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
