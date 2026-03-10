vim.keymap.set('n', '<leader>dn', function()
  require('dap-python').test_runner = 'pytest'
  require('dap-python').test_method()
end, { buffer = true, desc = 'Debug: Nearest Test (Python)' })
