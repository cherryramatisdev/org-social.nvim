local M = {}

local function parse_properties(content)
    local id, reply_to
    local in_properties = false
    local lines = vim.split(content, '\n')
    for _, line in ipairs(lines) do
        line = line:gsub('^%s+', ''):gsub('%s+$', '')
        if line == ':PROPERTIES:' then
            in_properties = true
        elseif in_properties and line == ':END:' then
            in_properties = false
            break
        elseif in_properties then
            local key, value = line:match('^:([%w_]+):%s*(.*)$')
            if key then
                if key == 'ID' then id = value end
                if key == 'REPLY_TO' then reply_to = value end
            end
        end
    end
    return id, reply_to
end

local function parse_posts(parsed_feeds)
    local all_posts = {}
    for username, feed in pairs(parsed_feeds) do
        for _, post in ipairs(feed.posts) do
            if post.content and #post.content > 0 then
                local post_copy = vim.deepcopy(post)
                post_copy.author = feed.metadata
                post_copy.author.username = username
                post_copy.id, post_copy.reply_to = parse_properties(post_copy.content)
                table.insert(all_posts, post_copy)
            end
        end
    end

    return all_posts
end

local function prepare_timeline_buffer(lines)
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

function M.render_timeline(parsed_feeds)
    local lines = {}
    local all_posts = parse_posts(parsed_feeds)

    local id_to_post = {}
    local parents = {}

    for _, post in ipairs(all_posts) do
        if post.id then id_to_post[post.id] = post end
        if not post.reply_to then table.insert(parents, post) end
    end

    for _, post in ipairs(all_posts) do
        if post.reply_to then
            local parent_id = post.reply_to:match('#([^#]+)$')
            local parent = parent_id and id_to_post[parent_id]
            if parent then
                parent.replies = parent.replies or {}
                table.insert(parent.replies, post)
            end
        end
    end

    table.sort(parents, function(a, b) return a.timestamp > b.timestamp end)
    for _, parent in ipairs(parents) do
        if parent.replies then
            table.sort(parent.replies, function(a, b) return a.timestamp > b.timestamp end)
        end
    end

    table.insert(lines, '#+TITLE: Org Social Timeline')
    table.insert(lines, '')
    table.insert(lines, "* Timeline")

    for _, parent in ipairs(parents) do
        table.insert(lines, string.format("** %s", parent.author.username or parent.author.NICK))
        table.insert(lines, "")
        vim.list_extend(lines, vim.split(parent.content, '\n'))

        if parent.replies then
            table.insert(lines, "*** Replies")

            for _, reply in ipairs(parent.replies) do
                table.insert(lines, string.format("**** %s", reply.author.username or reply.author.NICK))

                local reply_lines = vim.split(reply.content, '\n')
                for _, line in ipairs(reply_lines) do
                    table.insert(lines, line)
                end
            end
        end
    end

    prepare_timeline_buffer(lines)
end

return M
