return {
	"hrsh7th/nvim-cmp",
	event = "User FileOpened",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-nvim-lsp-signature-help",
	},
	enabled = true,
	config = function()
		local cmp = require('cmp')
		cmp.setup({
			snippet = {
				expand = function(args)
					require 'luasnip'.lsp_expand(args.body)
				end
			},
			completion = {
				autocomplete = false,
			},
      experimental = {
        ghost_text = true,
      },
			mapping = {
				['<Down>'] = {
					i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
				},
				['<Up>'] = {
					i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
				},
				['<C-b>'] = cmp.mapping.scroll_docs(-4),
				['<C-f>'] = cmp.mapping.scroll_docs(4),
				['<C-Space>'] = cmp.mapping.complete(),
				['<Esc>'] = cmp.mapping.abort(),
				["<Tab>"] = cmp.mapping(
					function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }), -- Taken from LunarVim
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
						fallback()
					end
				end, { "i", "s" }),
				['<CR>'] = cmp.mapping.confirm({ select = true }),

				--	['<CR>'] = cmp.mapping({
				--		i = function(fallback)
				--			if cmp.visible() and cmp.get_active_entry() then
				--				cmp.coinfirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
				--			else
				--				fallback()
				--			end
				--		end,
				--		s = cmp.mapping.confirm({ select = true }),
				--		c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
				--	}) --If nothing is selected (including preselections) add a newline as usual. If something has explicitly been selected by the user, select it.
			},
			sources = cmp.config.sources({
				{ name = 'nvim_lsp' },
				{ name = 'luasnip' },
				{ name = "nvim_lsp_signature_help" },
				-- more sources
			}, {
        { name = 'buffer' },
      }),
		})
	end
}
