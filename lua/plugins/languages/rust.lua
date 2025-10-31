return {
  {
    'rust-lang/rust.vim',
    ft = 'rust',
    init = function()
      vim.g.rustfmt_autosave = 1 -- format on save; drop if you prefer manual rustfmt
    end,
  },
}
