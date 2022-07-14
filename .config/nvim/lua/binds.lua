local nest = require('nest')

nest.applyKeymaps {
    {
        mode = 't', {
            { '<ESC>', '<C-\\><C-n>' }
        }
    },
    {
        '<leader>', {
            { 'd', ':NvimTreeToggle<CR>' },
            { 'ff', ':Telescope find_files<CR>' },
            { 'fg', ':Telescope live_grep<CR>' },
            { 'fb', ':Telescope buffers<CR>' },
            { 'fh', ':Telescope help_tags<CR>' },
        }
    }
}

