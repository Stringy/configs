
local cmp = require('cmp')

cmp.setup {
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
    },

    mapping = {
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({select = true})
    }
}

