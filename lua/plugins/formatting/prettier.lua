local supported = {
  'css',
  'graphql',
  'handlebars',
  'html',
  'javascript',
  'javascriptreact',
  'json',
  'jsonc',
  'less',
  'scss',
  'typescript',
  'typescriptreact',
  'vue',
  'yaml',
}

return {
  -- conform
  {
    'stevearc/conform.nvim',
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(supported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], 'prettier')
      end

      opts.format_after_save = function(bufnr)
        -- Disable formatting if global or buffer-local variable is set
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        -- Check if the filetype supports `prettier`
        local filetype = vim.bo[bufnr].filetype

        if vim.tbl_contains(supported, filetype) then
          return { formatters = { 'prettier' }, timeout_ms = 2000 }
        end

        -- Fallback to default LSP formatting
        return { lsp_format = 'fallback' }
      end
    end,
  },
}
