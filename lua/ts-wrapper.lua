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
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if not filename:match("%.org$") then
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
        print('ok_query', ok_query, 'query', vim.inspect(query))
        return {}
    end

    ---@type {name: string, url: string}[]
    local follows = {}

    for id, node, _ in query:iter_captures(self.root, bufnr) do
        local capture = query.captures[id]
        local node_value = vim.treesitter.get_node_text(node, bufnr)

        if capture == 'follow'  then
            local follow = vim.split(node_value, ' ')
            table.insert(follows, { name = follow[1], url = follow[2] })
        end
    end

    return follows
end

return TSWrapper
