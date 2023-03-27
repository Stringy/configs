local nest = require('nest')

nest.applyKeymaps {
    {
        mode = 't',
        {
            { '<ESC>', '<C-\\><C-n>' }
        }
    },
    {
        '<leader>', {
        { 'd',  ':NvimTreeToggle<CR>' },
        { 'ff', ':Telescope find_files<CR>' },
        { 'fg', ':Telescope live_grep<CR>' },
        { 'fb', ':Telescope buffers<CR>' },
        { 'fh', ':Telescope help_tags<CR>' },
        { 'fs', ':Telescope grep_string<CR>' },
        { 'ss', ':SymbolsOutline<CR>' },
        { 'fo', ':Goyo<CR>' },
        -- tab controls
        { '1',  '1gt' },
        { '2',  '2gt' },
        { '3',  '3gt' },
        { '4',  '4gt' },
        { '5',  '5gt' },
        { '6',  '6gt' },
        { '7',  '7gt' },
        { '8',  '8gt' },
        { '9',  '9gt' },
        { '0',  ':tablast<CR>' },

        { 'nn', require('stringy.trimmers').newlines },
    }
    }
}

local stringy = vim.api.nvim_create_augroup('STRINGY', { clear = true })

vim.api.nvim_create_autocmd('BufWritePre', {
    group = stringy,
    callback = require('stringy.trimmers').whitespace,
})
