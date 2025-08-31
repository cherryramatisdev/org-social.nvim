local M = {}

function M.render_timeline(parsed_feeds)
    local lines = {}

    for username, feed in pairs(parsed_feeds) do
        table.insert(lines, string.format("* %s - %s", feed.metadata.TITLE or "", feed.metadata.NICK or username))
        table.insert(lines, string.format(":PROPERTIES:"))
        table.insert(lines, string.format(":DESCRIPTION: %s", feed.metadata.DESCRIPTION or ""))
        table.insert(lines, string.format(":LINK: %s", feed.metadata.LINK or ""))
        table.insert(lines, string.format(":CONTACT: %s", feed.metadata.CONTACT or ""))
        if feed.metadata.AVATAR then
            table.insert(lines, string.format(":AVATAR: %s", feed.metadata.AVATAR))
        end
        table.insert(lines, string.format(":ENDPROPERTIES:"))
        table.insert(lines, string.format("** Follows"))

        for _, follow in ipairs(feed.follows) do
            table.insert(lines, string.format("- [[%s][%s]]", follow.url, follow.name))
        end

        table.insert(lines, "") -- Add empty line between feeds
    end

    local temp_file = vim.fn.tempname() .. '.org'
    vim.fn.writefile(lines, temp_file)
    vim.cmd.vsplit(temp_file)
    local buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_set_option_value('modified', false, { scope = 'local', buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', buf = buf })

    vim.api.nvim_create_autocmd({'BufDelete', 'BufWipeout'}, {
        buffer = buf,
        callback = function()
            if vim.fn.filereadable(temp_file) == 1 then
                os.remove(temp_file)
            end
        end
    })
end

return M
