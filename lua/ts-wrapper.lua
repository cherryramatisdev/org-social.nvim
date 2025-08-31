---@class TSWrapper
---@field parser TSParser
---@field tree TSTree
---@field root TSNode

local TSWrapper = {} --- [[@as TSWrapper]]

---@param bufnr integer
function TSWrapper:new(bufnr)
    local obj = {
        parser = nil,
        tree = nil,
        root = nil,
    }

    setmetatable(obj, self)
    self.__index = self

    obj:init_treesitter(bufnr)

    return obj
end

---@param bufnr integer
function TSWrapper:init_treesitter(bufnr)
    local filetype = vim.api.nvim_get_option_value('filetype', { scope = 'local', buf = bufnr })

    if filetype ~= 'org' then
        vim.notify("Not a Org file", vim.log.levels.ERROR)
        return nil
    end

    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "org")

    if not ok or not parser then
        vim.notify(
            "Org parser not available. Install and setup the nvim-orgmode plugin.",
            vim.log.levels.ERROR
        )
        return nil
    end

    local tree = parser:parse()[1]
    if not tree then
        vim.notify("Can't parse the buffer with treesitter", vim.log.levels.ERROR)
        return nil
    end

    local root = tree:root()
    if not root then
        vim.notify("Can't can't find tree root with treesitter", vim.log.levels.ERROR)
        return nil
    end

    self.parser = parser
    self.tree = tree
    self.root = root
end

---@param bufnr integer
---@return {name: string, url: string}[]
function TSWrapper:get_follows(bufnr)
    local lang = self.parser:lang()
    local ok_query, query = pcall(vim.treesitter.query.parse, lang, [[
    (document
        body: (body
          directive: (directive name: (expr) @name
                                value: (value) @follow
                                (#eq? @name "FOLLOW"))))
    ]])

    if not ok_query or not query then
        return {}
    end

    ---@type {name: string, url: string}[]
    local follows = {}

    for id, node, _ in query:iter_captures(self.root, bufnr) do
        local capture = query.captures[id]
        local node_value = vim.treesitter.get_node_text(node, bufnr)

        if capture == 'follow' then
            local follow = vim.split(node_value, ' ')
            table.insert(follows, { name = follow[1], url = follow[2] })
        end
    end

    return follows
end

function TSWrapper:get_metadata(bufnr)
    local lang = self.parser:lang()
    local ok_query, query = pcall(vim.treesitter.query.parse, lang, [[
        (document
            body: (body
              directive: (directive name: (expr) @name
                                    value: (value) @value
                                    (#not-eq? @name "FOLLOW")) @directive))
    ]])

    if not ok_query or not query then
        return {}
    end

    local metadata = {}

    for _, match, _ in query:iter_matches(self.root, bufnr) do
        local directive_data = {}

        for id, nodes in pairs(match) do
            local capture_name = query.captures[id]
            local node_text = vim.treesitter.get_node_text(nodes[1], bufnr)
            directive_data[capture_name] = node_text
        end

        if directive_data.name and directive_data.value then
            metadata[directive_data.name] = directive_data.value
        end
    end

    return metadata
end

function TSWrapper:get_posts(bufnr)
    local lang = self.parser:lang()
    local ok_query, query = pcall(vim.treesitter.query.parse, lang, [[
        (document
              subsection: (section
                    headline: (headline
                                item: (item) @headline)
                    ) @posts
              (#eq? @headline "Posts"))
    ]])

    if not ok_query or not query then
        return {}
    end

    local posts = {}

    for id, node, _ in query:iter_captures(self.root, bufnr) do
        local capture = query.captures[id]
        if capture == 'posts' then
            local raw_content = vim.treesitter.get_node_text(node, bufnr)
            raw_content = raw_content:gsub("* Posts", "")

            local raw_posts = vim.split(raw_content:gsub("\n%*%*%s*", "\0"), "\0")  -- Match \n** with optional spaces

            for _, post in ipairs(raw_posts) do
                if #post > 0 then
                    local id_line = post:match(":ID:%s+(.-)\n")
                    local date_id, datetime_str
                    if id_line then
                        date_id = id_line:gsub("\n", "")
                        datetime_str = date_id
                    end

                    if datetime_str then
                        local year, month, day, hour, min, sec = datetime_str:match(
                            "^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)")

                        local timestamp = datetime_str and os.time({
                            year = year,
                            month = month,
                            day = day,
                            hour = hour,
                            min = min,
                            sec = sec,
                        }) or 0

                        table.insert(posts, {
                            content = post,
                            id = date_id,
                            timestamp = timestamp
                        })
                    end

                end
            end
        end
    end

    return posts
end

return TSWrapper
