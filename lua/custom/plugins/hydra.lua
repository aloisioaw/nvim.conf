return {
  {
    'anuvyklack/hydra.nvim',
    config = function()
      local Hydra = require 'hydra'
      Hydra {
        name = 'Window Management',
        hint = 'Move: hjkl, Resize: < > + -, Exit: Esc',
        config = { invoke_on_body = true },
        mode = 'n',
        body = '<leader>w',
        heads = {
          { 'h', '<C-w>h' },
          { 'j', '<C-w>j' },
          { 'k', '<C-w>k' },
          { 'l', '<C-w>l' },
          { '+', '5<C-w>+' },
          { '-', '5<C-w>-' },
          { '<', '5<C-w><' },
          { '>', '5<C-w>>' },
          { '<Esc>', nil, { exit = true } },
        },
      }
    end,
  },
}
