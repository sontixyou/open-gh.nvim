# open-gh.nvim

A Neovim plugin to open the current file or selection on GitHub in your browser.

## Features

- Open the current file on GitHub (normal mode)
- Open the selected lines on GitHub with line number anchors (visual mode)
- Automatically detects git repository and branch
- Cross-platform support (macOS, Linux, Windows)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'sontixyou/open-gh.nvim',
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'sontixyou/open-gh.nvim'
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'sontixyou/open-gh.nvim'
```

## Usage

### Normal Mode

Open the current file on GitHub:

```vim
:OpenGH
```

### Visual Mode

Select lines and open them on GitHub with line number anchors:

1. Select lines in visual mode (`V`)
2. Run `:OpenGH`

The URL will include line numbers like `#L10-L20`.

## Requirements

- Neovim 0.7.0 or later
- Git repository with a GitHub remote
- A browser installed on your system

## How it works

The plugin:
1. Detects the git repository root
2. Gets the remote URL from `origin`
3. Determines the current branch
4. Calculates the relative file path
5. Constructs the GitHub URL
6. Opens the URL in your default browser

## License

MIT