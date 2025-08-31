local timeline = require('org-social.timeline')
local treesitter = require('ts-wrapper')

---@class SocialModule
---@field social_file string
---@field setup fun(opts: { social_file: string })

local M = {} --- [[@as SocialModule]]

---@param opts { social_file: string }
function M.setup(opts)
    if not opts.social_file then
        vim.notify('Please provide a social_file parameter to your .setup call', vim.log.levels.ERROR)
        return
    end

    M.social_file = opts.social_file
end

function M.open_timeline()
    local buf = vim.uri_to_bufnr(vim.uri_from_fname(M.social_file))

    if not vim.api.nvim_buf_is_loaded(buf) then
        vim.fn.bufload(buf)
    end

    local ts_wrapper = treesitter:new(buf)
    if not ts_wrapper then
        vim.notify("Failed to create treesitter wrapper for buffer.", vim.log.levels.ERROR)
        return
    end

    local follows = ts_wrapper:get_follows(buf)
    local timeline = timeline.parse_timeline(follows)
end

return M
