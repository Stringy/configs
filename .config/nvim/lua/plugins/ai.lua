local adapter = nil
if os.getenv('GEMINI_API_KEY') ~= nil then
    adapter = 'gemini'
elseif os.getenv('CODECOMPANION_URL') ~= nil then
    adapter = 'granite'
end

return {
    {
        "olimorris/codecompanion.nvim",
        config = true,
        cond = function()
            return adapter ~= nil
        end,
        opts = {
            display = {
                actions_palette = {
                    width = 95,
                    height = 10,
                    prompt = "Prompt ",                     -- Prompt used for interactive LLM calls
                    provider = "telescope",                 -- Can be "default", "telescope", or "mini_pick". If not specified, the plugin will autodetect installed providers.
                    opts = {
                        show_default_actions = true,        -- Show the default actions in the action palette?
                        show_default_prompt_library = true, -- Show the default prompt library in the action palette?
                    },
                },
            },
            adapters = {
                opts = {
                    show_defaults = false,
                },
                granite = function()
                    if os.getenv('CODECOMPANION_URL') == nil then
                        return nil
                    end

                    return require('codecompanion.adapters').extend('openai_compatible', {
                        env = {
                            url = os.getenv('CODECOMPANION_URL'),
                        },
                    })
                end
            },
            strategies = {
                chat = {
                    adapter = adapter
                },
                inline = {
                    adapter = adapter
                },
                cmd = {
                    adapter = adapter
                },
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
    },
    {
        "greggh/claude-code.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim", -- Required for git operations
        },
        config = function()
            require("claude-code").setup()
        end
    }
}
