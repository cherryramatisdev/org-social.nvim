vim.api.nvim_create_user_command('OrgSocialTimeline', function()
    require('org-social').open_timeline()
end, {})
