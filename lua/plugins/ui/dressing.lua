-- vim.ui.input() and vim.ui.select()
return {
  {
    'stevearc/dressing.nvim',
    opts = {
      select = {
        backend = { 'fzf_lua', 'builtin', 'nui' }, -- keep whatever global order you like
        get_config = function(opts)
          if opts.kind == 'project_search_dir' then
            return { backend = 'builtin' }
          end
        end,
      },
    },
  },
}
