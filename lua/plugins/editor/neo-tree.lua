return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
    },
    keys = {
      {
        '<leader>nr',
        ':Neotree reveal<CR>',
        desc = 'Reveal current file in Neo-tree',
      },
      {
        '<leader>nt',
        ':Neotree toggle<CR>',
        desc = 'Toggle Neotree',
      },
    },

    config = function()
      require('neo-tree').setup {
        hide_root_node = true, -- Hide the root node.
        source_selector = {
          winbar = true,
          statusline = false,
        },
      }

      -- neo-tree v3.x recursion guard:
      -- restore() used to focus node_id before clearing it, which can re-enter
      -- render_tree() and recurse indefinitely on newer nui/neo-tree combos.
      local renderer = require 'neo-tree.ui.renderer'
      if not renderer._restore_stack_overflow_patch then
        renderer.position.restore = function(state)
          if state._restoring_position then
            return
          end
          state._restoring_position = true

          local ok, err = pcall(function()
            if state.position.topline and state.position.lnum then
              vim.api.nvim_win_call(state.winid, function()
                vim.fn.winrestview({ topline = state.position.topline, lnum = state.position.lnum })
              end)
            end

            local node_id = state.position.node_id
            state.position.node_id = nil
            if node_id then
              renderer.focus_node(state, node_id, true)
            end

            renderer.position.restore_selection(state)
            renderer.position.clear(state)
          end)

          state._restoring_position = false
          if not ok then
            error(err)
          end
        end
        renderer._restore_stack_overflow_patch = true
      end
    end,
  },
}
