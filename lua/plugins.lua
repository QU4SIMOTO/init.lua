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

require("lazy").setup({
  -- main color scheme
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd [[colorscheme nord]]
      vim.g.nord_disable_background = true
      require("nord").set()
    end
  },
  -- git integration
  "tpope/vim-fugitive",
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end
  },
  -- nice bar at the bottom
  {
    "itchyny/lightline.vim",
    lazy = false,
    config = function()
      vim.o.showmode = false
      vim.g.lightline = {
	colorscheme = "one",
	active = {
	  left = {
	    { "mode",      "paste" },
	    { "gitbranch", "readonly", "filename", "modified" }
	  },
	  right = {
	    { "lineinfo" },
	    { "percent" },
	    { "fileencoding", "filetype" }
	  },
	},
	component_function = {
	  filename = "LightlineFilename",
	  gitbranch = "FugitiveHead"
	},
      }
      function LightlineFilenameInLua(opts)
	if vim.fn.expand("%:t") == "" then
	  return "[No Name]"
	else
	  return vim.fn.getreg("%")
	end
      end

      vim.api.nvim_exec(
      [[
      function! g:LightlineFilename()
      return v:lua.LightlineFilenameInLua()
      endfunction
      ]],
      true
      )
    end
  },
  -- nice startup page
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("alpha").setup(require("alpha.themes.startify").config)
    end
  },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      vim.keymap.set("", "<C-b>", "<cmd>NvimTreeToggle<cr>")
      require("nvim-tree").setup({
	filters = {
	  dotfiles = false,
	}
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup {
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },
	sync_install = false,
	auto_install = true,
	ignore_install = { "javascript" },
	highlight = {
	  enable = true,
	  additional_vim_regex_highlighting = false,
	}
      }
    end
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

      vim.keymap.set("n", "<leader>j", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<leader>k", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<leader>l", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<leader>;", function() harpoon:list():select(4) end)
      -- vim.keymap.set("n", "<C-l>", function() harpoon:list():select(5) end)
      harpoon.setup()
    end
  },
  -- better %
  {
    "andymass/vim-matchup",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end
  },
  {
    "nvim-telescope/telescope.nvim", tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      lspconfig.rust_analyzer.setup {
	settings = {
	  ["rust-analyzer"] = {
	    cargo = {
	      allFeatures = true,
	    },
	    imports = {
	      group = {
		enable = false,
	      },
	    },
	    completion = {
	      postfix = {
		enable = false,
	      },
	    },
	  },
	},
      }
      -- Bash LSP
      local configs = require "lspconfig.configs"
      if not configs.bash_lsp and vim.fn.executable("bash-language-server") == 1 then
	configs.bash_lsp = {
	  default_config = {
	    cmd = { "bash-language-server", "start" },
	    filetypes = { "sh" },
	    root_dir = require("lspconfig").util.find_git_ancestor,
	    init_options = {
	      settings = {
		args = {}
	      }
	    }
	  }
	}
      end
      if configs.bash_lsp then
	lspconfig.bash_lsp.setup {}
      end

      -- TS LSP
      lspconfig.tsserver.setup {}

      lspconfig.lua_ls.setup {
	on_init = function(client)
	  local path = client.workspace_folders[1].name
	  if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
	    return
	  end

	  client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
	    runtime = {
	      version = 'LuaJIT'
	    },
	    workspace = {
	      checkThirdParty = false,
	      library = {
		vim.env.VIMRUNTIME
	      }
	    }
	  })
	end,
	settings = {
	  Lua = {}
	}
      }

      -- Global mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
	  -- Enable completion triggered by <c-x><c-o>
	  vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

	  -- Buffer local mappings.
	  -- See `:help vim.lsp.*` for documentation on any of the below functions
	  local opts = { buffer = ev.buf }
	  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
	  -- vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
	  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	  vim.keymap.set("n", "<C-f>", function()
	    vim.lsp.buf.format { async = true }
	  end, opts)

	  local client = vim.lsp.get_client_by_id(ev.data.client_id)

	  client.server_capabilities.semanticTokensProvider = nil
	end,
      })
    end
  },
  -- LSP-based code-completion
  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      'hrsh7th/vim-vsnip',
    },
    config = function()
      local cmp = require "cmp"

      cmp.setup({
	snippet = {
	  -- REQUIRED by nvim-cmp. get rid of it once we can
	  expand = function(args)
	    vim.fn["vsnip#anonymous"](args.body)
	  end,
	},
	mapping = cmp.mapping.preset.insert({
	  ["<C-b>"] = cmp.mapping.scroll_docs(-4),
	  ["<C-f>"] = cmp.mapping.scroll_docs(4),
	  ["<C-Space>"] = cmp.mapping.complete(),
	  ["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
	  { name = "nvim_lsp" },
	}, {
	  { name = "path" },
	}),
	experimental = {
	  ghost_text = true,
	},
      })

      -- Enable completing paths in :
      cmp.setup.cmdline(":", {
	sources = cmp.config.sources({
	  { name = "path" }
	})
      })
    end
  },
  -- inline function signatures
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      -- Get signatures (and _only_ signatures) when in argument lists.
      require "lsp_signature".setup({
	doc_lines = 0,
	handler_opts = {
	  border = "none"
	},
      })
    end
  },
  "cespare/vim-toml",
  {
    "cuducos/yaml.nvim",
    ft = { "yaml" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  -- rust
  {
    "rust-lang/rust.vim",
    ft = { "rust" },
    config = function()
      vim.g.rustfmt_autosave = 1
      vim.g.rustfmt_emit_files = 1
      vim.g.rustfmt_fail_silently = 0
      vim.g.rust_clip_command = "wl-copy"
    end
  },
  -- markdown
  {
    "plasticboy/vim-markdown",
    ft = { "markdown" },
    dependencies = {
      "godlygeek/tabular",
    },
    config = function()
      -- never ever fold!
      vim.g.vim_markdown_folding_disabled = 1
      -- support front-matter in .md files
      vim.g.vim_markdown_frontmatter = 1
      -- "o" on a list item should insert at same level
      vim.g.vim_markdown_new_list_item_indent = 0
      -- don"t add bullets when wrapping:
      -- https://github.com/preservim/vim-markdown/issues/232
      vim.g.vim_markdown_auto_insert_bullets = 0
    end
  },
})
