## (wip) org-social.nvim

> WARN: This repo is under construction, use it at your own risk.

An Neovim client for [Org Social](https://github.com/tanrax/org-social), a decentralized social network that works with Org Mode files over HTTP.

## Demo - 31/09/2025

[![demo](https://asciinema.org/a/736914.svg)](https://asciinema.org/a/736914)

## Dependencies

This plugin rely heavily on [nvim-orgmode](https://github.com/nvim-orgmode/orgmode) to provide the tree-sitter grammar used in queries for parsing.

## Installation

You can use any package manager to install and setup this plugin.

**vim.pack** If you have nvim 0.12+ you should be able to use the new builtin package manager to install it.

```lua
--- after/plugin/org-social.lua

vim.pack.add({
    { src = 'https://github.com/cherryramatisdev/org-social.nvim', version = 'main' },
    { src = 'https://github.com/nvim-orgmode/orgmode', version = 'master' }
})

if not pcall(require, 'orgmode') then
    return
end

require'orgmode'.setup {}

if not pcall(require, 'org-social') then
    return
end

-- TOOD: still reviewing the parameters necessary
require'org-social'.setup {
    social_file = vim.fn.expand("path to your social.org file"),
    path = 'url to your social.org file',
    nickname = 'nickname that you go by'
}
```

**lazy.nvim** Or if you prefer a more standard plugin:

```lua
{
  'cherryramatisdev/org-social.nvim',
  event = 'VeryLazy',
  dependencies = {
      { 'nvim-orgmode/orgmode', config = true }
  },
  config = function()
    -- TOOD: still reviewing the parameters necessary
    require('org-social').setup {
        social_file = vim.fn.expand("path to your social.org file"),
        path = 'url to your social.org file',
        nickname = 'nickname that you go by'
    }
  end,
}
```

## Usage

1. `OrgSocialTimeline` :: This command open a new buffer loading your timeline that consist of the posts people you follow made and what their interaction with your posts were.
    a) `OrgSocialReplyToPost` :: When on the timeline, you can run this command to reply the current focused post.
2. `OrgSocialNewPost` :: A capture window for quickly making a new post.
2. `OrgSocialEditFile` :: Open your static file so you can edit it manually.
