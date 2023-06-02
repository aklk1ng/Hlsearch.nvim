local M = {}
local api, fn = vim.api, vim.fn
local group = api.nvim_create_augroup('Hlsearch', { clear = true })
local ns_id = api.nvim_create_namespace('hlsearch')

function M:render()
  local bufnr = api.nvim_get_current_buf()
  if vim.v.hlsearch == 0 then
    api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    return
  end

  api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  local line = api.nvim_win_get_cursor(0)[1] - 1
  local col = api.nvim_win_get_cursor(0)[2]

  local ok, search = pcall(fn.searchcount)
  local currentline = api.nvim_get_current_line()
  if currentline:find(fn.getreg('/')) then
    if ok and search.total then
      local current = search.current
      local count = math.min(search.total, search.maxcount)

      local opts = {
        virt_text = { { '<--' .. current .. '/' .. count, 'MatchParen' } },
      }
      api.nvim_buf_set_extmark(bufnr, ns_id, line, col, opts)
    end
  end
end

local buffers = {}
local function hs_event(bufnr)
  if buffers[bufnr] then
    return
  end
  buffers[bufnr] = true
  local cm_id = api.nvim_create_autocmd('CursorHold', {
    buffer = bufnr,
    group = group,
    callback = function()
      M:render()
    end,
  })
  api.nvim_create_autocmd('BufDelete', {
    buffer = bufnr,
    group = group,
    callback = function(opt)
      buffers[bufnr] = nil
      pcall(api.nvim_del_autocmd, cm_id)
      pcall(api.nvim_del_autocmd, opt.id)
    end,
  })
end

function M.setup()
  api.nvim_create_autocmd({ 'BufWinEnter' }, {
    pattern = '*',
    group = group,
    callback = function(opt)
      hs_event(opt.buf)
    end,
  })
end

return M