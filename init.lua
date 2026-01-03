-- Basic settings
vim.opt.hlsearch = true
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.spelllang = "en_us"

vim.o.guifont = "JetBrainsMono Nerd Font Mono:h12"

-- Leader (this is here so plugins etc pick it up)
vim.g.mapleader = "," -- anywhere you see <leader> means hit ,

-- Leader key timeout (in milliseconds)
vim.opt.timeoutlen = 3000 -- 3 seconds - adjust as needed

-- use nvim-tree instead
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- MacOS command key
if vim.g.neovide then
	vim.keymap.set("n", "<D-s>", ":w<CR>") -- Save
	vim.keymap.set("v", "<D-c>", '"+y') -- Copy
	vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
	vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
	vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
	vim.keymap.set("i", "<D-v>", "<C-R>+") -- Paste insert mode
end

-- Display settings
vim.opt.termguicolors = true
vim.o.background = "dark"

-- Scrolling and UI settings
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.sidescrolloff = 8
vim.opt.scrolloff = 8

-- Title
vim.opt.title = true

-- Function to extract last 2 path segments for titlestring
local function get_last_two_path_segments(path)
	-- Handle empty or root path
	if not path or path == "/" then
		return "/"
	end

	-- Remove trailing slash for consistent splitting
	if path:sub(-1) == "/" then
		path = path:sub(1, -2)
	end

	-- Split the path by "/" and collect segments
	local segments = {}
	for segment in path:gmatch("[^/]+") do
		table.insert(segments, segment)
	end

	-- Return the last two segments, or fewer if not available
	if #segments == 0 then
		return "/"
	elseif #segments == 1 then
		return segments[1]
	else
		return segments[#segments - 1] .. "/" .. segments[#segments]
	end
end

-- Function to update titlestring with current directory
local function update_titlestring()
	local cwd = vim.fn.getcwd()
	local display_path = get_last_two_path_segments(cwd)
	vim.opt.titlestring = display_path
end

-- Update titlestring on startup and when directory changes
vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
	callback = update_titlestring,
})

-- Persist undo (persists your undo history between sessions)
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.undofile = true

-- Tab stuff
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Search configuration
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.gdefault = true

-- open new split panes to right and below (as you probably expect)
vim.opt.splitright = true
vim.opt.splitbelow = true

-- LSP
vim.lsp.inlay_hint.enable(true)

local plugins = {
	{ "nvim-lua/plenary.nvim" }, -- used by other plugins
	{ "nvim-tree/nvim-web-devicons" }, -- used by other plugins

	-- Gruvbox theme (feel free to choose another!)
	{ "ellisonleao/gruvbox.nvim" },

	{ "nvim-lualine/lualine.nvim" }, -- status line
	{ "nvim-tree/nvim-tree.lua" }, -- file browser

	-- Telescope command menu
	{ "nvim-telescope/telescope.nvim" },
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{ "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },

	-- TreeSitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- LSP stuff
	{ "neovim/nvim-lspconfig" }, -- configures LSPs

	-- Some LSPs don't support formatting, this fills the gaps
	{ "stevearc/conform.nvim" },

	{
		"saghen/blink.cmp",
		version = "1.*",
		opts_extend = { "sources.default" },
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{ "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },
}

-- Plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(plugins)

vim.cmd.colorscheme("gruvbox") -- activate the theme
require("lualine").setup() -- the status line
require("nvim-tree").setup({
	update_focused_file = {
		enable = true,
		update_root = false,
		ignore_list = {},
	},
	view = {
		width = 30,
	},
}) -- the tree file browser panel
local lga_actions = require("telescope-live-grep-args.actions")
require("telescope").setup({
	extensions = {
		live_grep_args = {
			auto_quoting = true,
			mappings = {
				i = {
					["<C-k>"] = lga_actions.quote_prompt(),
					["<C-space>"] = lga_actions.to_fuzzy_refine,
				},
			},
		},
	},
}) -- command menu
require("telescope").load_extension("live_grep_args")
require("bufferline").setup({})

vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>")

-- Auto-open nvim-tree on startup with empty buffer on the right
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Only auto-open if no file arguments were passed
		if vim.fn.argc() == 0 then
			-- Open nvim-tree
			require("nvim-tree.api").tree.open()

			-- Move to the right window and create an empty buffer
			vim.cmd("wincmd l")

			-- If we're still in the tree (no window on the right), create a new vertical split
			if vim.bo.filetype == "NvimTree" then
				vim.cmd("vsplit")
				vim.cmd("enew")
			end
		end
	end,
})

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"typescript",
		"python",
		"rust",
		"go",
		"ledger",
		"haskell",
		"nix",
	},
	sync_install = false,
	auto_install = true,
	highlight = { enable = true },
})

-- some stuff so code folding uses treesitter instead of older methods
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99

require("conform").setup({
	log_level = vim.log.levels.DEBUG,
	default_format_opts = {
		async = true,
		lsp_format = "never",
	},
	format_on_save = function(bufnr)
		-- Disable format_on_save when variable is set
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return {
			timeout_ms = 10000,
			lsp_format = "never",
		}
	end,
	formatters_by_ft = {
		lua = { "stylua" },
		json = { "prettier" },
		nix = { "nixfmt" },
		haskell = { "ormolu" },
		ledger = { "hledger-fmt" },
		cabal = { "cabal_fmt" },
		yaml = { "yamlfmt" },
	},
	formatters = {
		["hledger-fmt"] = {
			command = "hledger-fmt",
			inherit = false,
			args = { "--no-diff", "--fix", "--exit-zero-on-changes", "$FILENAME" },
			stdin = false,
		},
	},
})

-- Toggle format on save
vim.api.nvim_create_user_command("FormatToggle", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	print("Format on save: " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
end, {})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", function()
	require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "Telescope live grep with args" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

-- Buffer management
vim.keymap.set("n", "<leader>bd", ":bp|bd #<CR>", { desc = "Close buffer, keep window" })

-- Function to close all buffers except visible ones
local function close_other_buffers()
	local visible_buffers = {}
	-- Collect visible buffers
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		visible_buffers[buf] = true
	end

	-- Delete non-visible buffers
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and not visible_buffers[buf] then
			vim.api.nvim_buf_delete(buf, { force = false })
		end
	end
end

vim.keymap.set("n", "<leader>bc", close_other_buffers, { desc = "Close other buffers" })
