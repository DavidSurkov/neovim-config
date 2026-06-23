local mini_files_root

local normalize_path = function(path)
  if path == nil or path == '' then
    return path
  end

  local normalized = vim.fs.normalize(path)
  return normalized ~= '/' and normalized:gsub('/+$', '') or normalized
end

local set_mini_files_root = function()
  mini_files_root = normalize_path(vim.fn.getcwd())
end

local mini_files_git_cache = {}

local mini_files_git_icons = {
  added = '+ ',
  conflict = 'U ',
  deleted = '- ',
  ignored = 'I ',
  modified = '~ ',
  renamed = 'R ',
  untracked = '? ',
}

local mini_files_git_hl = {
  added = 'MiniFilesGitAdded',
  conflict = 'MiniFilesGitConflict',
  deleted = 'MiniFilesGitDeleted',
  ignored = 'MiniFilesGitIgnored',
  modified = 'MiniFilesGitModified',
  renamed = 'MiniFilesGitRenamed',
  untracked = 'MiniFilesGitUntracked',
}

local mini_files_git_priority = {
  ignored = 1,
  untracked = 2,
  modified = 3,
  added = 4,
  renamed = 5,
  deleted = 6,
  conflict = 7,
}

local set_mini_files_git_hl = function()
  local highlights = {
    MiniFilesGitAdded = 'GitSignsAdd',
    MiniFilesGitConflict = 'DiagnosticError',
    MiniFilesGitDeleted = 'GitSignsDelete',
    MiniFilesGitIgnored = 'Comment',
    MiniFilesGitModified = 'GitSignsChange',
    MiniFilesGitRenamed = 'GitSignsChange',
    MiniFilesGitUntracked = 'GitSignsAdd',
  }

  for group, link in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, { default = true, link = link })
  end
end

local get_mini_files_git_root = function(path, fs_type)
  local dir = fs_type == 'directory' and path or vim.fs.dirname(path)
  local git_dir = vim.fs.find('.git', { path = dir, upward = true })[1]

  return git_dir and vim.fs.dirname(git_dir) or nil
end

local parse_mini_files_git_status = function(line)
  local status = line:sub(1, 2)
  local rel_path = line:sub(4)

  if rel_path == '' then
    return nil, nil
  end

  local rename_to = rel_path:match '^.+ %-> (.+)$'
  if rename_to then
    rel_path = rename_to
  end

  local index_status = status:sub(1, 1)
  local worktree_status = status:sub(2, 2)

  if status:find('U', 1, true) or status == 'AA' or status == 'DD' then
    return rel_path, 'conflict'
  end

  if status == '!!' then
    return rel_path, 'ignored'
  end

  if status == '??' then
    return rel_path, 'untracked'
  end

  if index_status == 'R' or index_status == 'C' then
    return rel_path, 'renamed'
  end

  if index_status == 'D' or worktree_status == 'D' then
    return rel_path, 'deleted'
  end

  if index_status == 'A' or worktree_status == 'A' then
    return rel_path, 'added'
  end

  if index_status ~= ' ' or worktree_status ~= ' ' then
    return rel_path, 'modified'
  end
end

local pick_mini_files_git_status = function(current, candidate)
  if current == nil then
    return candidate
  end

  return mini_files_git_priority[candidate] > mini_files_git_priority[current] and candidate or current
end

local get_mini_files_git_statuses = function(root)
  local now = vim.loop.hrtime()
  local max_cache_age = 300000000000

  for cached_root, cache_entry in pairs(mini_files_git_cache) do
    if now - cache_entry.updated_at > max_cache_age then
      mini_files_git_cache[cached_root] = nil
    end
  end

  local cached = mini_files_git_cache[root]

  if cached and now - cached.updated_at < 2000000000 then
    return cached.statuses
  end

  local statuses = {}
  local command = { 'git', '-C', root, 'status', '--porcelain=v1', '--ignored=matching', '--untracked-files=all' }
  local result = vim.system(command, { text = true }):wait()

  if result.code == 0 then
    for line in vim.gsplit(result.stdout, '\n', { plain = true, trimempty = true }) do
      local rel_path, status = parse_mini_files_git_status(line)

      if rel_path and status then
        local path = normalize_path(vim.fs.joinpath(root, rel_path))
        statuses[path] = pick_mini_files_git_status(statuses[path], status)
      end
    end
  end

  mini_files_git_cache[root] = {
    statuses = statuses,
    updated_at = now,
  }

  return statuses
end

local get_mini_files_git_status = function(fs_entry)
  local root = get_mini_files_git_root(fs_entry.path, fs_entry.fs_type)

  if root == nil then
    return nil
  end

  local path = normalize_path(fs_entry.path)
  local statuses = get_mini_files_git_statuses(root)
  local status = statuses[path]

  if fs_entry.fs_type == 'directory' then
    local prefix = path .. '/'

    for changed_path, changed_status in pairs(statuses) do
      if changed_status ~= 'ignored' and vim.startswith(changed_path, prefix) then
        status = pick_mini_files_git_status(status, changed_status)
      end
    end
  end

  return status
end

local mini_files_git_prefix = function(fs_entry)
  local icon, icon_hl = MiniFiles.default_prefix(fs_entry)
  local status = get_mini_files_git_status(fs_entry)

  if status == nil then
    return '  ' .. icon, icon_hl
  end

  return mini_files_git_icons[status] .. icon, mini_files_git_hl[status]
end

local mini_files_git_highlight = function(fs_entry)
  local status = get_mini_files_git_status(fs_entry)

  if status == nil then
    return MiniFiles.default_highlight(fs_entry)
  end

  return mini_files_git_hl[status]
end

return {
  {
    'echasnovski/mini.nvim',
    keys = {
      {
        '<leader>nr',
        function()
          set_mini_files_root()

          -- Safely get the active buffer's path and reveal it
          local buf_name = vim.api.nvim_buf_get_name(0)
          if vim.fn.filereadable(buf_name) == 1 then
            require('mini.files').open(buf_name)
          else
            require('mini.files').open(mini_files_root)
          end
        end,
        desc = 'Reveal current file in MiniFiles',
      },
      {
        '<leader>nt',
        function()
          -- Toggle the file explorer cleanly
          if not require('mini.files').close() then
            set_mini_files_root()
            require('mini.files').open(mini_files_root)
          end
        end,
        desc = 'Toggle MiniFiles',
      },
    },
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      set_mini_files_git_hl()
      require('mini.files').setup {
        content = {
          highlight = mini_files_git_highlight,
          prefix = mini_files_git_prefix,
        },
        options = {
          use_as_default_explorer = true,
        },
      }

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id

          vim.keymap.set('n', 'h', function()
            local explorer = require 'mini.files'
            local state = explorer.get_explorer_state()
            local focused_dir = state and state.branch[state.depth_focus]
            local root = mini_files_root or vim.fn.getcwd()

            if normalize_path(focused_dir) == normalize_path(root) then
              vim.notify('Access Denied: Cannot ascend past project root!', vim.log.levels.WARN)
            else
              explorer.go_out()
            end
          end, { buffer = buf_id, desc = 'Go out to parent directory (Restricted to PWD)' })

          vim.keymap.set(
            'n',
            '<C-s>',
            require('mini.files').synchronize,
            { buffer = buf_id, desc = 'Save file system changes' }
          )
        end,
      })

      require('mini.surround').setup {
        mappings = {
          add = 'gsa',
          delete = 'gsd',
          find = 'gsf',
          find_left = 'gsF',
          highlight = 'gsh',
          replace = 'gsr',
          update_n_lines = 'gsn',
        },
      }

      require('mini.move').setup {
        mappings = {
          left = 'H',
          right = 'L',
          down = 'J',
          up = 'K',
          line_left = '',
          line_right = '',
          line_down = '',
          line_up = '',
        },
      }

      local statusline = require 'mini.statusline'
      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
            local git = MiniStatusline.section_git { trunc_width = 40 }
            local diff = MiniStatusline.section_diff { trunc_width = 75 }
            local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
            local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
            local filename = MiniStatusline.section_filename { trunc_width = 140 }
            local location = MiniStatusline.section_location { trunc_width = 75 }
            local search = MiniStatusline.section_searchcount { trunc_width = 75 }

            local dap_status = ''
            if package.loaded['dap'] and require('dap').status() ~= '' then
              dap_status = '  ' .. require('dap').status()
            end

            return MiniStatusline.combine_groups {
              { hl = mode_hl, strings = { mode } },
              {
                hl = 'MiniStatuslineDevinfo',
                strings = { git, diff, diagnostics, lsp },
              },
              '%<', -- Mark general truncate point
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=', -- End left alignment
              { hl = 'MiniStarterItemPrefix', strings = { dap_status } },
              { hl = mode_hl, strings = { search, location } },
            }
          end,
        },
      }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
