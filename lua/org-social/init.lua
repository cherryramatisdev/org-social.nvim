local timeline = require('org-social.timeline')
local view = require('org-social.view')
local treesitter = require('ts-wrapper')


---@class SocialModule
---@field social_file string
---@field nickname string
---@field path string
---@field setup fun(opts: { social_file: string })

local M = {} --- [[@as SocialModule]]

---@param opts { social_file: string, path: string, nickname: string }
function M.setup(opts)
    if not opts.social_file or not opts.path or not opts.nickname then
        vim.notify('Please provide a social_file, path and nickname as parameters to your .setup call. For more information on each parameter, run :h org-social', vim.log.levels.ERROR)
        return
    end

    M.social_file = opts.social_file
    M.path = opts.path
    M.nickname = opts.nickname
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

    local metadata = ts_wrapper:get_metadata(buf)

    local follows = ts_wrapper:get_follows(buf)

    table.insert(follows, { name = M.nickname, url = M.path })

    timeline.parse_timeline(follows, function(parsed_feeds)
        view.render_timeline(parsed_feeds)
    end)
end

function M.edit_file()
    vim.cmd.tabedit(M.social_file)
end

function M.new_post()
    local centered_window = function(content, opts)
        opts = opts or {}
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local buf = vim.api.nvim_create_buf(false, true)

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
        vim.api.nvim_set_option_value('buftype', 'acwrite', { scope = 'local', buf = buf })
        vim.api.nvim_set_option_value('filetype', 'org', { scope = 'local', buf = buf })

        local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            style = 'minimal',
            title = opts.title,
            title_pos = 'center',
            border = opts.border or 'rounded'
        })

        return buf, win
    end

    local id = os.date("%Y-%m-%dT%H:%M:%S%z")
    local temp_file = vim.fn.tempname() .. '.org'

    local boilerplate = {
        '**',
        ':PROPERTIES:',
        ':ID: ' .. id,
        ':END:',
        '',
        'Post body',
    }

    local buf, win = centered_window(boilerplate, { title = ' [Press ZZ to save or ZQ to cancel] ' })
    vim.api.nvim_buf_set_name(buf, temp_file)

    -- NOTE: Activate select mode so the user has a "placeholder feel" to the post body text.
    vim.api.nvim_win_set_cursor(win, { 6, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('v$<C-g>', true, false, true), 'n', false)

    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = function()
            local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

            vim.fn.writefile(content, M.social_file, 'a')

            vim.schedule(function()
                vim.api.nvim_buf_delete(buf, { force = true })
                os.remove(temp_file)
            end)
        end,
        once = true
    })

    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
        buffer = buf,
        callback = function()
            if vim.fn.filereadable(temp_file) == 1 then
                os.remove(temp_file)
            end
        end,
        once = true
    })
end

return M
