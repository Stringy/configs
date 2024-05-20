local T = {}

T.toggle_theme = function()
    if (vim.o.background == "light") then
        vim.o.background = "dark"
    else
        vim.o.background = "light"
    end
end

return T
