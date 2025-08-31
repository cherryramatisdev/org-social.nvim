vim.api.nvim_create_user_command('OrgSocialTimeline', function()
    require('org-social').open_timeline()
end, { nargs = 0 })

vim.api.nvim_create_user_command('OrgSocialEditFile', function()
    require('org-social').edit_file()
end, { nargs = 0 })

vim.api.nvim_create_user_command('OrgSocialNewPost', function()
    require('org-social').new_post()
end, { nargs = 0 })
