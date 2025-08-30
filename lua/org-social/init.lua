local treesitter = require 'ts-wrapper'
local curl = require 'plenary.curl'

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

    vim.fn.bufload(buf)

    local ts_wrapper = treesitter:new(buf)

    if not ts_wrapper then
        return
    end

    local follows = ts_wrapper:get_follows(buf)

    local CONCURRENCY = 5
    local semaphore = CONCURRENCY

    -- Create table to collect responses
    local responses = {}
    local pending = #follows

    for _, follow in ipairs(follows) do
        vim.schedule(function()
            semaphore = semaphore - 1
            if semaphore < 0 then return end

            local res = curl.request {
                url = follow.url,
                method = "get",
                accept = "text/plain",
            }

            if res.status ~= 200 then
                vim.notify('Failed to fetch ' .. follow.url, vim.log.levels.ERROR)
            else
                -- Create temporary buffer for parsing
                local temp_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(temp_buf, "social_temp.org")
                vim.api.nvim_set_option_value('filetype', 'org', { scope = 'local', buf = temp_buf })
                vim.fn.bufload(temp_buf)
                vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, vim.split(res.body, '\n'))

                -- Parse with treesitter
                local temp_ts = treesitter:new(temp_buf)
                if temp_ts then
                    responses[follow.name] = {
                        follows = temp_ts:get_follows(temp_buf),
                    }
                end
                vim.api.nvim_buf_delete(temp_buf, { force = true })
            end

            pending = pending - 1
            semaphore = semaphore + 1

            if pending == 0 then
                vim.notify('Finished loading ' .. #vim.tbl_keys(responses) .. ' feeds')
            end
        end)
    end
end

return M
