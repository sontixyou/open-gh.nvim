local M = {}

-- Get the git root directory
local function get_git_root()
  local result = vim.fn.system("git rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.fn.trim(result)
end

-- Get the git remote URL
local function get_git_remote_url()
  local result = vim.fn.system("git config --get remote.origin.url")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.fn.trim(result)
end

-- Get the current branch name
local function get_current_branch()
  local result = vim.fn.system("git rev-parse --abbrev-ref HEAD")
  if vim.v.shell_error ~= 0 then
    return "main"
  end
  local branch = vim.fn.trim(result)
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
    cmd = { "open", url }
  elseif vim.fn.has("unix") == 1 then
    cmd = { "xdg-open", url }
  elseif vim.fn.has("win32") == 1 then
    -- Windows requires special handling with proper escaping
    -- Escape special characters for cmd.exe
    local escaped_url = url:gsub('"', '""')  -- Escape double quotes
    escaped_url = escaped_url:gsub('&', '^&')  -- Escape ampersands
    escaped_url = escaped_url:gsub('%%', '%%')  -- Escape percent signs
    escaped_url = escaped_url:gsub('%^', '^^')  -- Escape carets
    cmd = string.format('cmd.exe /c start "" "%s"', escaped_url)
    local result = vim.fn.system(cmd)
    return vim.v.shell_error == 0
  else
    vim.notify("Unsupported operating system", vim.log.levels.ERROR)
    return false
  end
  
  -- For Unix-like systems, use jobstart for better error handling
  local ok, job_id = pcall(vim.fn.jobstart, cmd, {
    detach = true,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.schedule(function()
          vim.notify("Failed to open URL (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
        end)
      end
    end
  })
  
  return ok and job_id > 0
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
function M.open_visual(line_start, line_end)
  -- Use provided line numbers from command range
  line_start = line_start or vim.fn.line("'<")
  line_end = line_end or vim.fn.line("'>")
  M.open_github({ line_start = line_start, line_end = line_end })
end

return M
