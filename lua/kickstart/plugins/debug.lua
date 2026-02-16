-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function() require('dap').continue() end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function() require('dap').step_into() end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function() require('dap').step_over() end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function() require('dap').step_out() end,
      desc = 'Debug: Step Out',
    },
    {
      '<F12>',
      function() require('dap').disconnect() end,
      desc = 'Debug: Disconnect',
    },
    {
      '<leader>b',
      function() require('dap').toggle_breakpoint() end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function() require('dapui').toggle() end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'debugpy',
      },
    }

    -- 1. Get the existing configurations for python
    -- (This ensures we don't overwrite what Mason-DAP already created)
    local configurations = dap.configurations.python or {}

    -- 2. Define a function to update the PYTHONPATH
    local function add_src_to_path(configs)
      for _, config in ipairs(configs) do
        -- Initialize env if it doesn't exist
        config.env = config.env or {}

        -- We use ${workspaceFolder} because nvim-dap resolves this
        -- to the root directory of your project automatically.
        config.env.PYTHONPATH = '${workspaceFolder}:${workspaceFolder}/src'
      end
    end

    -- 3. Apply the fix to current and future configurations
    add_src_to_path(configurations)
    dap.configurations.python = configurations

    pythonPath_func =
      function()
        -- 1. Check if we are in a 'uv' project
        local venv_path = os.getenv 'VIRTUAL_ENV' or io.popen('uv venv --show'):read '*l'

        if venv_path and venv_path ~= '' then
          -- Return the path to the python executable inside the uv venv
          return venv_path .. '/bin/python'
        end

        -- 2. Fallback to system python if uv isn't initialized
        return '/usr/bin/python3'
      end, table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Pytest: Current File',
        module = 'pytest', -- This is the magic line
        args = {
          '${file}',
          '-sv', -- -s shows print output, -v is verbose
        },
        console = 'integratedTerminal',
        env = {
          -- Re-applying your src path fix here as well!
          PYTHONPATH = '${workspaceFolder}:${workspaceFolder}/src',
        },
      })

    table.insert(dap.configurations.python, {
      type = 'python',
      request = 'launch',
      name = 'uv: Pytest Current File',
      -- We use 'uv' to launch the module
      module = 'pytest',
      -- uv handles the environment, so we just pass the file
      args = { '${file}', '-sv' },
      -- This tells nvim-dap to use the 'uv' execution context
      pythonPath = pythonPath_func,
      -- uv is smart enough to find the src folder if it's in your pyproject.toml,
      -- but we keep this here as a safety net:
      env = { PYTHONPATH = '${workspaceFolder}/src' },
    })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }
  end,
}
