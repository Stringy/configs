local T = {}

local trimmer = function(pattern)
    local ft = vim.bo.filetype
    -- we don't trim diffs or binaries, because that makes no sense
    if ft == 'diff' or ft == 'binary' then
        return
    end

    local view_save = vim.fn.winsaveview()
    vim.cmd([[
        keeppatterns ]] .. pattern .. [[
    ]])
    vim.fn.winrestview(view_save)
end

T.whitespace = function()
    trimmer([[%s/\s\+$//e]])
end

T.newlines = function()
    trimmer([[%s/\n*\%$//e]])
end

return T
