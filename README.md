# toggl-track.nvim

**Early / experimental** Neovim plugin to start/stop Toggl Track timers from inside Neovim.\
Workspaces, projects and tags are discovered automatically (or lazily) and the plugin talks to the Toggl Track API **asynchronously** using [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim).

> ⚠️ **Status:** first-cut / early version — features are incomplete and the project is under lazy/slow development. Use it if you like tinkering; PRs, issues and improvements are very welcome.

______________________________________________________________________

## ✨ Features

- Pure Lua implementation.
- Optional Telescope integration for nicer pickers.
- Minimal runtime state (workspace, project, current entry).

______________________________________________________________________

## 📦 Requirements

- Neovim (>= 0.7)
- [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)

______________________________________________________________________

## 🔧 Installation

Using **lazy.nvim**:

```lua
{
  "sanzharkuandyk/toggl-track.nvim",
  config = function()
    require("toggl-track").setup({
      api_token = os.getenv("TOGGL_API_TOKEN"), -- your Toggl API token
      picker = "telescope", -- or "native"
    })
  end,
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
}
```

______________________________________________________________________

## ⚙️ Configuration

```lua
require("toggl-track").setup({
  api_token = nil,         -- your Toggl API token (required)
  auto_bootstrap = true,   -- fetch workspace + projects on startup
  default_desc = "nvim task", -- description if none given
  notify = true,           -- show notifications
  picker = "native",       -- "native" or "telescope"
})
```

______________________________________________________________________

## 🛠️ Commands

| Command | Description |
| -------------------- | -------------------------------------------------- |
| `:TogglStart [desc]` | Start timer with optional description/project |
| `:TogglStop` | Stop the current timer |
| `:TogglCurrent` | Show info about the current timer |
| `:TogglProjects` | Select project and start timer |
| `:TogglWorkspaces` | Select workspace (and reload projects) |

______________________________________________________________________

## 🤝 Contributing

This plugin is very early-stage. If you find bugs, want to improve docs or add features — PRs and issues are welcome.

______________________________________________________________________

## 🔍 Alternatives & Acknowledgements

- **[toggl.nvim](https://github.com/williambdean/toggl.nvim)** — another Neovim plugin offering Toggl integration.
