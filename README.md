## (wip) org-social.nvim

> WARN: This repo is under construction, use it at your own risk.

An Neovim client for [Org Social](https://github.com/tanrax/org-social), a decentralized social network that works with Org Mode files over HTTP.

## Dependencies

This plugin rely heavily on [nvim-orgmode](https://github.com/nvim-orgmode/orgmode) to provide the tree-sitter grammar used in queries for parsing.

## Installation

You can use any package manager to install and setup this plugin.

**vim.pack** If you have nvim 0.12+ you should be able to use the new builtin package manager to install it.

```lua
--- after/plugin/org-social.lua

vim.pack.add({
    { src = 'https://github.com/cherryramatisdev/org-social.nvim', version = 'main' }
})

if not pcall(require, 'org-social') then
    return
end

-- TOOD: still reviewing the parameters necessary
require'org-social'.setup {
    social_file = vim.fn.expand("path to your social.org file")
}
```

**lazy.nvim** Or if you prefer a more standard plugin:

```lua
{
  'cherryramatisdev/org-social.nvim',
  event = 'VeryLazy',
  config = function()
    -- TOOD: still reviewing the parameters necessary
    require('org-social').setup {
        social_file = vim.fn.expand("path to your social.org file")
    }
  end,
}
```

## Usage

1. `OrgSocialTimeline` :: This command open a new buffer loading your timeline that consist of the posts people you follow made and what their interaction with your posts were.
    a) `OrgSocialReplyToPost` :: When on the timeline, you can run this command to reply the current focused post.
2. `OrgSocialNewPost` :: A capture window for quickly making a new post.
2. `OrgSocialOpenFile` :: Open your static file so you can edit it manually.
