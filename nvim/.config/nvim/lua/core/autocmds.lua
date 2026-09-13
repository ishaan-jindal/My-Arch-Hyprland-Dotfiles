-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 120 })
  end,
})

-- Diagnostics configuration: no virtual_text, floating with border
vim.diagnostic.config({
  virtual_text = false,
  float = {
    border = "rounded",
    source = "if_many",
  },
  update_in_insert = false,
  severity_sort = true,
})

-- Show diagnostics on hover (CursorHold), skipped when a float is already open
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
      if ok and cfg.relative ~= "" then
        return
      end
    end
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

-- Auto-resize splits when terminal window is resized
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Filetype-specific indentation (4 spaces for these languages)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "java", "kotlin", "go", "c", "cpp" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Remove trailing whitespace on save (skip non-modifiable/special buffers)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    if not vim.bo.modifiable or vim.bo.buftype ~= "" then
      return
    end
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
