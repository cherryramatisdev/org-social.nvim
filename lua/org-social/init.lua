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

local function load_timeline(opts)
    local follows = opts.ts_wrapper:get_follows(opts.buf)

    table.insert(follows, { name = M.nickname, url = M.path })

    timeline.parse_timeline(follows, function(parsed_feeds)
        local lines = view.render_timeline(parsed_feeds)
        vim.fn.writefile(lines, opts.temp_file)

        opts.open_win(opts.temp_file)

        local timeline_buf = vim.api.nvim_get_current_buf()

        vim.api.nvim_set_option_value('modified', false, { scope = 'local', buf = timeline_buf })
        vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', buf = timeline_buf })

        vim.keymap.set('n', 'gq', 'ZQ', { desc = '[Org social] Quit timeline buffer', buffer = true })

        vim.keymap.set('n', '<c-r>', function()
            load_timeline {
                buf = opts.buf,
                ts_wrapper = opts.ts_wrapper,
                temp_file = opts.temp_file,
                open_win = function(temp_file)
                    vim.cmd.edit(temp_file)
                end
            }
        end, { desc = '[Org social] Refresh the buffer', buffer = true })

        vim.keymap.set('n', '<leader>n', function()
            M.new_post {}
        end, { desc = '[Org social] Create new post', buffer = true })

        vim.keymap.set('n', '<leader>r', function()
            if not opts.ts_wrapper then return nil end

            local current_post_reply_id = opts.ts_wrapper:get_current_post_reply_id(vim.api.nvim_get_current_buf())
            if current_post_reply_id and current_post_reply_id.id then
                M.new_post { reply_id = current_post_reply_id.id }
            else
                vim.notify('The post should have an proper :ID:, so we can reply to', vim.log.levels.ERROR)
            end
        end, { desc = '[Org social] Reply to a post', buffer = true })

        vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
            buffer = timeline_buf,
            callback = function()
                if vim.fn.filereadable(opts.temp_file) == 1 then
                    os.remove(opts.temp_file)
                end
            end
        })
    end)
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

    load_timeline {
        buf = buf,
        ts_wrapper = ts_wrapper,
        temp_file = vim.fn.tempname() .. '.org',
        open_win = function(temp_file)
            vim.cmd.vsplit(temp_file)
        end
    }
end

function M.edit_file()
    vim.cmd.tabedit(M.social_file)
end

function M.new_post(opts)
    local centered_window = function(content, win_opts)
        win_opts = win_opts or {}
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
            title = win_opts.title,
            title_pos = 'center',
            border = win_opts.border or 'rounded'
        })

        return buf, win
    end

    local id = os.date("%Y-%m-%dT%H:%M:%S%z")
    local temp_file = vim.fn.tempname() .. '.org'

    -- TODO: The correct format for a reply is the user URL to `social.org` plus `#` and then the reply_id:
    -- e.g https://andros.dev/static/social.org#2025-09-03T12:12:57+0200
    local boilerplate = {
        '**',
        ':PROPERTIES:',
        ':ID: ' .. id,
        opts.reply_id and ':REPLY_TO: ' .. opts.reply_id or '',
        ':END:',
        '',
        'Post body',
    }

    local buf, win = centered_window(boilerplate, { title = ' [Press ZZ to save or ZQ to cancel] ' })
    vim.api.nvim_buf_set_name(buf, temp_file)

    -- NOTE: Activate select mode so the user has a "placeholder feel" to the post body text.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('Gv$<C-g>', true, false, true), 'n', false)

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
