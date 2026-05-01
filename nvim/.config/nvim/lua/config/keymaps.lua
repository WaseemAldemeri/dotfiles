-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode with jk" })

-- ─── Zed-style bindings ──────────────────────────────────────────────────────

-- ctrl-p: find files (Zed / VSCode muscle memory). LazyVim uses <leader>ff by default.
vim.keymap.set("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })

-- ctrl-b: toggle file tree (like Zed's left dock)
vim.keymap.set("n", "<C-b>", "<cmd>Neotree toggle<cr>", { desc = "Toggle File Tree" })

-- space y / space p: clipboard yank/paste (Zed's "space y" / "space p")
-- Note: LazyVim has <leader>Y for clipboard yank-line but not <leader>y in normal mode.
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to Clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from Clipboard" })
-- Visual paste: preserve clipboard so yanked text isn't overwritten by the replaced text
vim.keymap.set("v", "<leader>p", '"+P', { desc = "Paste from Clipboard (keep)" })

-- space o: open recent files (Zed's "projects::OpenRecent")
vim.keymap.set("n", "<leader>o", "<cmd>Telescope oldfiles<cr>", { desc = "Recent Files" })

-- space g d / space g r: LSP aliases with leader prefix (base gd/gr already work)
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
vim.keymap.set("n", "<leader>gr", "<cmd>Telescope lsp_references<cr>", { desc = "Find References" })

-- space r n: rename (LazyVim default is <leader>cr)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })

-- space d: diagnostics panel (LazyVim default is <leader>cd for line / <leader>xx for list)
vim.keymap.set("n", "<leader>d", "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" })

-- ] g / [ g: git hunk navigation (Zed's "]g"/"[g"; LazyVim uses ]h/[h via gitsigns)
vim.keymap.set("n", "]g", function() require("gitsigns").next_hunk() end, { desc = "Next Git Hunk" })
vim.keymap.set("n", "[g", function() require("gitsigns").prev_hunk() end, { desc = "Prev Git Hunk" })

-- space t: stage/unstage hunk (Zed's "editor::ToggleSelectedDiffHunks")
vim.keymap.set("n", "<leader>t", function() require("gitsigns").stage_hunk() end, { desc = "Stage Hunk" })

-- space b: fold function bodies (Zed's "editor::FoldFunctionBodies" — closest Neovim equiv is zM)
vim.keymap.set("n", "<leader>b", "zM", { desc = "Fold All" })

-- Shift-J/K in visual: move lines (Zed behavior; LazyVim uses <A-j>/<A-k> — both will work)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move Lines Down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move Lines Up" })
