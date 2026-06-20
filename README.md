<div align="center">
<samp>

# telescope-maccy.nvim

Integration for [Maccy](https://github.com/p0deje/Maccy) with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

</samp>
</div>

> [!CAUTION]
> Please note that this is currently at an experimental stage. Breaking changes may occur.

![telescope-maccy demo](vhs/demo.gif)

## Requirements

- macOS, with Maccy installed
- Neovim >= 0.10 (uses `vim.system()`)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- `sqlite3` on your `PATH` (ships with macOS)

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

| Option            | Default     | Description                                                       |
| ----------------- | ----------- | ----------------------------------------------------------------- |
| `db_path`         | _see above_ | Path to Maccy's `Storage.sqlite` (`~` is expanded).               |
| `limit`           | `500`       | Max entries fetched per launch, newest first.                     |
| `pin_to_top`      | `false`     | Float Maccy-pinned entries to the top, prefixed with 📌.          |
| `large_text`      | _see above_ | Skip loading bodies larger than `threshold` bytes when `enabled`. |
| `on_select`       | copy        | Function run with the selected entry on `<CR>` (see below).       |
| `attach_mappings` | _nil_       | Telescope `attach_mappings`, run after the defaults (see below).  |

Options can also be passed per call: `:Telescope maccy limit=20 pin_to_top=true`.

### Customizing the select action

By default `<CR>` copies the entry into the registers. Pass `on_select` to run
your own action instead — it receives the entry (`value` is the raw text, `nil`
for large entries; also `is_large`, `pinned`, `body`). The picker is closed
before it runs:

```lua
maccy = {
  on_select = function(entry)
    if entry.value then
      vim.api.nvim_paste(entry.value, true, -1) -- paste at the cursor
    end
  end,
}
```

For full control over the picker (extra keymaps, keeping it open, replacing
actions), pass an `attach_mappings` function. It runs after the default
mappings, so you can add keys or replace `<CR>` with
`actions.select_default:replace` (which then takes precedence over `on_select`):

```lua
maccy = {
  attach_mappings = function(_, map)
    map({ "i", "n" }, "<C-y>", function(prompt_bufnr)
      local entry = require("telescope.actions.state").get_selected_entry()
      require("telescope.actions").close(prompt_bufnr)
      if entry and entry.value then
        vim.fn.setreg("+", entry.value)
      end
    end)
    return true
  end,
}
```

See `:help telescope-maccy` for the full documentation.

## Development

```bash
make test          # run the Plenary/Busted suite locally
nix flake check    # run tests + lint/format in a reproducible sandbox
nix fmt            # format all files
nix run .#vhs      # record the demo
```

## License

MIT
