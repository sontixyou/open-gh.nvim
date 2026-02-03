-- Prevent loading the plugin twice
if vim.g.loaded_open_gh then
  return
end
vim.g.loaded_open_gh = 1

-- Common command handler
local function handle_open_gh(opts)
  local open_gh = require('open-gh')
  
  -- opts.range == 2 indicates a visual selection range
  if opts.range == 2 then
    open_gh.open_visual(opts.line1, opts.line2)
  else
    open_gh.open_normal()
  end
end

-- Create user commands
vim.api.nvim_create_user_command('OpenGH', handle_open_gh, {
  range = true,
  desc = 'Open current file or selection on GitHub'
})

-- Create command alias with lowercase
vim.api.nvim_create_user_command('Opengh', handle_open_gh, {
  range = true,
  desc = 'Open current file or selection on GitHub (alias)'
})
