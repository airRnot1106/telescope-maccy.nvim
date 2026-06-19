# telescope-maccy.nvim

Browse [Maccy](https://maccy.app/) clipboard history from
[Telescope](https://github.com/nvim-telescope/telescope.nvim).

Maccy ships no CLI, IPC, or AppleScript API, so this extension reads Maccy's
Core Data SQLite store directly — **read-only**, never writing to it. Fuzzy-find
a past clipboard entry and load it back into your registers.

## Features

- Fuzzy-search your Maccy clipboard history, newest first
- Full-text preview of the unmodified entry
- `<CR>` loads the raw value into the `+` and `"` registers — paste with
  Neovim's own commands
- Optional pinning of Maccy-pinned entries to the top
- Skips loading very large entries to keep the picker snappy
- `:checkhealth telescope-maccy`

## Requirements

- macOS, with Maccy installed
- Neovim >= 0.10 (uses `vim.system()`)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- `sqlite3` on your `PATH` (ships with macOS)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "airRnot1106/telescope-maccy.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").load_extension("maccy")
  end,
}
```

## Usage

```vim
:Telescope maccy
```

or from Lua:

```lua
require("telescope").extensions.maccy.maccy()
```

Press `<CR>` to copy the selected entry into the `+` (system clipboard) and `"`
(unnamed) registers, then paste with `p`, `"+p`, or `<C-r>"`.

## Configuration

Configure through Telescope's `extensions` table. Defaults shown:

```lua
require("telescope").setup({
  extensions = {
    maccy = {
      db_path = "~/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy/Storage.sqlite",
      limit = 500,
      pin_to_top = false,
      large_text = { enabled = true, threshold = 102400 }, -- 100 KiB
    },
  },
})
require("telescope").load_extension("maccy")
```

| Option       | Default     | Description                                                       |
| ------------ | ----------- | ----------------------------------------------------------------- |
| `db_path`    | _see above_ | Path to Maccy's `Storage.sqlite` (`~` is expanded).               |
| `limit`      | `500`       | Max entries fetched per launch, newest first.                     |
| `pin_to_top` | `false`     | Float Maccy-pinned entries to the top, prefixed with 📌.          |
| `large_text` | _see above_ | Skip loading bodies larger than `threshold` bytes when `enabled`. |

Options can also be passed per call: `:Telescope maccy limit=20 pin_to_top=true`.

See `:help telescope-maccy` for the full documentation.

## How it works

The database is opened read-only via a `file:...?mode=ro` URI and never
modified. Read-only (not `immutable=1`) is deliberate: Maccy keeps live history
in the write-ahead log (`Storage.sqlite-wal`), which `immutable=1` would ignore
— reading an empty or stale snapshot. A read-only connection honours the WAL and
does not block Maccy. Only plain-text entries are listed; the list is re-queried
fresh on every launch. Displayed text is folded to a single line, but the value
loaded into your registers is always the original.

## Limitations

- macOS only.
- Read-only: no delete or pin editing — manage history from Maccy itself.
- Text only: image and file-URL entries are not supported.

## Development

```bash
make test          # run the Plenary/Busted suite locally
nix flake check    # run tests + lint/format in a reproducible sandbox
nix fmt            # format all files
nix run .#vhs      # record the demo
```

## License

MIT
