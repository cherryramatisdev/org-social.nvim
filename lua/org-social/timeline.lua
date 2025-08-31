local treesitter = require('ts-wrapper')

local M = {}

---@param follows {name: string, url: string}[]
---@param on_result fun(results: table)
local function fetch_timeline(follows, on_result)
    local results = {}
    local pending_tasks = #follows

    local function job_callback(err, data)
        if err then
            vim.notify(err, vim.log.levels.ERROR)
        else
            table.insert(results, { follow = data.follow, data = table.concat(data.data, '\n') })
        end

        pending_tasks = pending_tasks - 1
        if pending_tasks == 0 then
            on_result(results)
        end
    end

    for _, follow in ipairs(follows) do
        local cmd = { "curl", "-s", "-H", "Accept: text/plain", follow.url }

        vim.fn.jobstart(cmd, {
            on_exit = function(_, exit_code, _)
                if exit_code ~= 0 then
                    job_callback('curl job failed with code: ' .. exit_code, nil)
                end
            end,
            on_stdout = function(_, data, _)
                if #data[1] > 0 then
                    job_callback(nil, { follow = follow, data = data })
                end
            end,
        })
    end
end

function M.parse_timeline(follows)
    fetch_timeline(follows, function(results)
        local parsed_feeds = {}

        for _, result in ipairs(results) do
            local temp_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_option_value('filetype', 'org', { scope = 'local', buf = temp_buf })
            vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, vim.split(result.data, '\n'))

            local temp_ts = treesitter:new(temp_buf)

            if temp_ts then
                parsed_feeds[result.follow.name] = { metadata = temp_ts:get_metadata(temp_buf), follows = temp_ts:get_follows(temp_buf) }
            end
            vim.api.nvim_buf_delete(temp_buf, {})
        end

        print('parsed_feeds', vim.inspect(parsed_feeds))
    end)
end

return M
