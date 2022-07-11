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
        }
    }
}

