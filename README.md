# toggl-track.nvim

**Early / experimental** Neovim plugin to start/stop Toggl Track timers from inside Neovim.\
Workspaces, projects and tags are discovered automatically (or lazily) and the plugin talks to the Toggl Track API **asynchronously** using [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim).

> ⚠️ **Status:** first-cut / early version — features are incomplete and the project is under lazy/slow development. Use it if you like tinkering; PRs, issues and improvements are very welcome.

______________________________________________________________________

## ✨ Features

- Start / stop Toggl timers from Neovim (async, non-blocking).
- Auto-discover workspaces and projects (configurable).
- Keeps minimal runtime state (workspace, project, current entry).
- Built-in commands for quick usage.
- Uses `plenary.curl` so Neovim never blocks on requests.

______________________________________________________________________

## 📦 Requirements

- Neovim (>= 0.7)
- [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)

______________________________________________________________________

## 🔧 Installation

### lazy.nvim

```lua
    {
        "sanzharkuandyk/toggl-track.nvim",
        config = function()
            require("toggl-track").setup({
                api_token = env.TOGGL_API_TOKEN -- api token from toggl,
            })
        end,
        dependencies = { "nvim-lua/plenary.nvim" },
    },
```

## 🛠️ ommands

```lua
:TogglStart "My Project"
:TogglCurrent
:TogglStop
:TogglProjects
```
