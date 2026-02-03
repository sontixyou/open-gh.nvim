-- Prevent loading the plugin twice
if vim.g.loaded_open_gh then
  return
end
vim.g.loaded_open_gh = 1

-- Create user commands
vim.api.nvim_create_user_command('OpenGH', function(opts)
  local open_gh = require('open-gh')
  
  -- Check if we're in visual mode
  if opts.range == 2 then
    open_gh.open_visual()
  else
    open_gh.open_normal()
  end
end, {
  range = true,
  desc = 'Open current file or selection on GitHub'
})

-- Create command alias with lowercase
vim.api.nvim_create_user_command('Opengh', function(opts)
  vim.cmd('OpenGH')
end, {
  range = true,
  desc = 'Open current file or selection on GitHub (alias)'
})
