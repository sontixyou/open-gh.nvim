local M = {}

-- Get the git root directory
local function get_git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return result:gsub("%s+$", "")
end

-- Get the git remote URL
local function get_git_remote_url()
  local handle = io.popen("git config --get remote.origin.url 2>/dev/null")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return result:gsub("%s+$", "")
end

-- Get the current branch name
local function get_current_branch()
  local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  if not handle then
    return "main"
  end
  local result = handle:read("*a")
  handle:close()
  local branch = result:gsub("%s+$", "")
  return branch ~= "" and branch or "main"
end

-- Convert git URL to GitHub web URL
local function git_url_to_github_url(git_url)
  if not git_url or git_url == "" then
    return nil
  end
  
  -- Handle SSH format: git@github.com:user/repo.git
  local user, repo = git_url:match("git@github%.com:([^/]+)/(.+)%.git")
  if user and repo then
    return string.format("https://github.com/%s/%s", user, repo)
  end
  
  -- Handle HTTPS format: https://github.com/user/repo.git
  user, repo = git_url:match("https://github%.com/([^/]+)/(.+)%.git")
  if user and repo then
    return string.format("https://github.com/%s/%s", user, repo)
  end
  
  -- Handle HTTPS format without .git: https://github.com/user/repo
  user, repo = git_url:match("https://github%.com/([^/]+)/(.+)")
  if user and repo then
    return string.format("https://github.com/%s/%s", user, repo)
  end
  
  return nil
end

-- Get relative path from git root
local function get_relative_path(file_path, git_root)
  if not git_root or git_root == "" then
    return nil
  end
  
  -- Normalize paths
  local normalized_file = file_path:gsub("//+", "/")
  local normalized_root = git_root:gsub("//+", "/")
  
  -- Remove git root from file path
  if normalized_file:sub(1, #normalized_root) == normalized_root then
    local relative = normalized_file:sub(#normalized_root + 1)
    -- Remove leading slash
    if relative:sub(1, 1) == "/" then
      relative = relative:sub(2)
    end
    return relative
  end
  
  return nil
end

-- Open URL in browser
local function open_url(url)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    cmd = "start"
  else
    vim.notify("Unsupported operating system", vim.log.levels.ERROR)
    return false
  end
  
  local full_cmd = string.format("%s '%s'", cmd, url)
  local result = os.execute(full_cmd)
  return result == 0 or result == true
end

-- Main function to open GitHub
function M.open_github(opts)
  opts = opts or {}
  
  -- Get current file path
  local file_path = vim.fn.expand("%:p")
  if file_path == "" then
    vim.notify("No file is currently open", vim.log.levels.ERROR)
    return
  end
  
  -- Get git information
  local git_root = get_git_root()
  if not git_root or git_root == "" then
    vim.notify("Not a git repository", vim.log.levels.ERROR)
    return
  end
  
  local git_url = get_git_remote_url()
  local github_url = git_url_to_github_url(git_url)
  if not github_url then
    vim.notify("Could not determine GitHub URL", vim.log.levels.ERROR)
    return
  end
  
  local relative_path = get_relative_path(file_path, git_root)
  if not relative_path then
    vim.notify("Could not determine relative path", vim.log.levels.ERROR)
    return
  end
  
  local branch = get_current_branch()
  
  -- Build the URL
  local url = string.format("%s/blob/%s/%s", github_url, branch, relative_path)
  
  -- Add line numbers if provided
  if opts.line_start then
    if opts.line_end and opts.line_end ~= opts.line_start then
      url = string.format("%s#L%d-L%d", url, opts.line_start, opts.line_end)
    else
      url = string.format("%s#L%d", url, opts.line_start)
    end
  end
  
  -- Open the URL
  if open_url(url) then
    vim.notify("Opened: " .. url, vim.log.levels.INFO)
  else
    vim.notify("Failed to open URL", vim.log.levels.ERROR)
  end
end

-- Open GitHub for current file (normal mode)
function M.open_normal()
  M.open_github()
end

-- Open GitHub for selected lines (visual mode)
function M.open_visual()
  local line_start = vim.fn.line("'<")
  local line_end = vim.fn.line("'>")
  M.open_github({ line_start = line_start, line_end = line_end })
end

return M
