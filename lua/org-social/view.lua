local M = {}

function M.render_timeline(parsed_feeds)
    local lines = {}
    local all_posts = {}

    for username, feed in pairs(parsed_feeds) do
        for _, post in ipairs(feed.posts) do
            if post.content and #post.content > 0 then
                local post_copy = vim.deepcopy(post)
                post_copy.author = feed.metadata
                post_copy.author.username = username
                table.insert(all_posts, post_copy)
            end
        end
    end

    table.sort(all_posts, function(a, b)
        return a.timestamp > b.timestamp
    end)

    table.insert(lines, '#+TITLE: Org Social Timeline')
    table.insert(lines, '')
    table.insert(lines, "* Timeline")

    for _, post in ipairs(all_posts) do
        table.insert(lines, string.format("** %s",
            post.author.username or post.author.NICK
        ))

        table.insert(lines, "")
        local content_lines = vim.split(post.content, '\n')
        for _, line in ipairs(content_lines) do
            table.insert(lines, line)
        end
    end

    local temp_file = vim.fn.tempname() .. '.org'
    vim.fn.writefile(lines, temp_file)
    vim.cmd.vsplit(temp_file)

    local buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_set_option_value('modified', false, { scope = 'local', buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', buf = buf })

    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
        buffer = buf,
        callback = function()
            if vim.fn.filereadable(temp_file) == 1 then
                os.remove(temp_file)
            end
        end
    })
end

return M
