return {
  {
    'ThePrimeagen/git-worktree.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('git-worktree').setup()
      require('telescope').load_extension('git_worktree')

      local worktree = require('git-worktree')
      worktree.on_tree_change(function(op, metadata)
        if op == worktree.Operations.Switch then
          vim.notify('Switched to: ' .. metadata.path, vim.log.levels.INFO)
        elseif op == worktree.Operations.Create then
          vim.notify('Created worktree: ' .. metadata.path, vim.log.levels.INFO)
        elseif op == worktree.Operations.Delete then
          vim.notify('Deleted worktree: ' .. metadata.path, vim.log.levels.INFO)
          local branch = vim.fn.fnamemodify(metadata.path, ':t')
          vim.ui.select({ 'Yes', 'No' }, { prompt = 'Delete local branch "' .. branch .. '"?' }, function(choice)
            if choice ~= 'Yes' then
              return
            end
            local result = vim.fn.system(string.format('git branch -d %s 2>&1', vim.fn.shellescape(branch)))
            if vim.v.shell_error ~= 0 then
              vim.notify('Could not delete branch (try -D if unmerged):\n' .. result, vim.log.levels.WARN)
            else
              vim.notify('Deleted branch: ' .. branch, vim.log.levels.INFO)
            end
          end)
        end
      end)

      -- Create a new worktree branched from origin/main
      vim.keymap.set('n', '<leader>gwc', function()
        vim.ui.input({ prompt = 'Branch name: ' }, function(branch)
          if not branch or branch == '' then
            return
          end
          local path = vim.fn.expand('~') .. '/worktrees/' .. branch
          vim.fn.mkdir(path, 'p')
          local result = vim.fn.system(
            string.format('git worktree add -B %s %s origin/main 2>&1', vim.fn.shellescape(branch), vim.fn.shellescape(path))
          )
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to create worktree:\n' .. result, vim.log.levels.ERROR)
            return
          end
          require('git-worktree').switch_worktree(path)
        end)
      end, { desc = '[G]it [W]orktree [C]reate (from origin/main)' })

      -- Create a worktree from a remote branch (for PR review)
      vim.keymap.set('n', '<leader>gwr', function()
        vim.ui.input({ prompt = 'Remote branch to review: ' }, function(branch)
          if not branch or branch == '' then
            return
          end
          local fetch = vim.fn.system(string.format('git fetch origin %s 2>&1', vim.fn.shellescape(branch)))
          if vim.v.shell_error ~= 0 then
            vim.notify('Fetch failed:\n' .. fetch, vim.log.levels.ERROR)
            return
          end
          local path = vim.fn.expand('~') .. '/worktrees/' .. branch
          vim.fn.mkdir(path, 'p')
          local result = vim.fn.system(
            string.format('git worktree add -B %s %s origin/%s 2>&1', vim.fn.shellescape(branch), vim.fn.shellescape(path), vim.fn.shellescape(branch))
          )
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to create worktree:\n' .. result, vim.log.levels.ERROR)
            return
          end
          require('git-worktree').switch_worktree(path)
        end)
      end, { desc = '[G]it [W]orktree [R]eview remote branch' })

      -- Push current branch to origin (sets upstream on first push)
      vim.keymap.set('n', '<leader>gwP', function()
        local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>&1'):gsub('\n', '')
        if vim.v.shell_error ~= 0 then
          vim.notify('Not in a git repo', vim.log.levels.ERROR)
          return
        end
        local result = vim.fn.system(string.format('git push -u origin %s 2>&1', vim.fn.shellescape(branch)))
        if vim.v.shell_error ~= 0 then
          vim.notify('Push failed:\n' .. result, vim.log.levels.ERROR)
        else
          vim.notify('Pushed ' .. branch .. ' to origin', vim.log.levels.INFO)
        end
      end, { desc = '[G]it [W]orktree [P]ush branch to origin' })

      -- Open gh pr create in a terminal in the current buffer's directory
      vim.keymap.set('n', '<leader>gwpr', function()
        local dir = vim.fn.expand('%:p:h')
        require('toggleterm.terminal').Terminal:new({ cmd = 'gh pr create', dir = dir, close_on_exit = false }):toggle()
      end, { desc = '[G]it [W]orktree [PR] create' })

      -- List worktrees: <Enter> to switch, <C-d> to delete
      vim.keymap.set('n', '<leader>gwl', function()
        require('telescope').extensions.git_worktree.git_worktrees()
      end, { desc = '[G]it [W]orktree [L]ist' })
    end,
  },
}
