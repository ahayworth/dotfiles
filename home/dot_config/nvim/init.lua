vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function safe_require(module)
  local ok, value = pcall(require, module)
  return ok and value or nil
end

local function setup(module, opts)
  local plugin = safe_require(module)
  if plugin and plugin.setup then
    plugin.setup(opts or {})
  end
  return plugin
end

local function executable(command)
  return vim.fn.executable(command) == 1
end

local function map(mode, lhs, rhs, desc, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { desc = desc }, opts or {}))
end

vim.pack.add({
  "https://github.com/tpope/vim-fugitive",
  "https://github.com/christoomey/vim-tmux-navigator",
  "https://github.com/kylechui/nvim-surround",
  "https://github.com/numToStr/Comment.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/ellisonleao/gruvbox.nvim",
  "https://github.com/neovim-treesitter/treesitter-parser-registry",
  "https://github.com/neovim-treesitter/nvim-treesitter",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/terrastruct/d2-vim",
  "https://github.com/vmware-tanzu/ytt.vim",
}, { confirm = false, load = true })

for option, value in pairs({
  background = "dark",
  belloff = "all",
  completeopt = { "menu", "menuone", "popup", "noselect", "noinsert" },
  copyindent = true,
  encoding = "utf-8",
  expandtab = true,
  foldenable = false,
  foldmethod = "manual",
  foldnestmax = 5,
  hlsearch = true,
  ignorecase = true,
  linebreak = true,
  matchtime = 3,
  mouse = "",
  number = true,
  shiftwidth = 2,
  showmatch = true,
  signcolumn = "yes",
  smartcase = true,
  tabstop = 2,
  termguicolors = true,
  title = true,
  updatetime = 750,
  wildmode = "list:longest",
}) do
  vim.opt[option] = value
end

vim.g.is_posix = 1

map("n", "Q", "gQ", "Enter Ex mode intentionally")
map("n", "<Leader>l", "<Cmd>set cursorline!<CR>", "Toggle cursor line")
map("n", "<Leader>c", "<Cmd>set cursorcolumn!<CR>", "Toggle cursor column")
map({ "n", "x", "o" }, "j", "gj", "Move down by display line")
map({ "n", "x", "o" }, "k", "gk", "Move up by display line")

local function show_search()
  vim.opt.hlsearch = true
  pcall(function()
    vim.v.hlsearch = 1
  end)
end

local function hide_search()
  vim.cmd("nohlsearch")
end

map("n", "[oh", show_search, "Show search highlights")
map("n", "]oh", hide_search, "Hide search highlights")
map("n", "coh", function()
  if vim.v.hlsearch == 1 then
    hide_search()
  else
    show_search()
  end
end, "Toggle search highlights")

for lhs, desc in pairs({ ["*"] = "Search word", ["/"] = "Search forward", ["?"] = "Search backward" }) do
  map("n", lhs, function()
    vim.fn.setreg("/", "")
    show_search()
    return lhs
  end, desc .. " and show highlights", { expr = true })
end

vim.filetype.add({
  extension = {
    bzl = "starlark",
    cue = "cue",
    d2 = "d2",
    hcl = "hcl",
    star = "starlark",
    tf = "terraform",
    tfvars = "terraform-vars",
  },
  filename = {
    BUILD = "starlark",
    Tiltfile = "starlark",
    WORKSPACE = "starlark",
  },
})

pcall(vim.treesitter.language.register, "bash", { "sh", "bash", "zsh" })
pcall(vim.treesitter.language.register, "hcl", { "terraform", "terraform-vars", "hcl" })

setup("nvim-treesitter")
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

setup("gruvbox", {
  contrast = "hard",
  italic = { comments = true, strings = true, emphasis = true, folds = true },
})
pcall(vim.cmd.colorscheme, "gruvbox")

vim.api.nvim_set_hl(0, "CursorLine", { bg = "#5f0000", fg = "white" })
vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#5f0000", fg = "white" })
vim.api.nvim_set_hl(0, "WhiteSpaceEOL", { bg = "darkgreen" })

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
  callback = function()
    if vim.bo.buftype == "" then
      if vim.w.whitespace_eol_match then
        pcall(vim.fn.matchdelete, vim.w.whitespace_eol_match)
      end
      vim.w.whitespace_eol_match = vim.fn.matchadd("WhiteSpaceEOL", [[\s\+$]])
    end
  end,
})

setup("nvim-surround")
setup("Comment")
setup("lualine", {
  options = {
    component_separators = "",
    icons_enabled = true,
    section_separators = "",
    theme = "gruvbox",
  },
  sections = {
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", "encoding", "fileformat", "filetype" },
  },
})

local function trim_buffer_whitespace(bufnr)
  if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then
    return
  end

  local view = vim.fn.winsaveview()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local changed = false

  for i, line in ipairs(lines) do
    lines[i] = line:gsub("%s+$", "")
    changed = changed or lines[i] ~= line
  end

  while #lines > 1 and lines[#lines] == "" do
    lines[#lines] = nil
    changed = true
  end

  if changed then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end
  vim.fn.winrestview(view)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(ev)
    trim_buffer_whitespace(ev.buf)
  end,
})

local conform = safe_require("conform")
if conform then
  local js_formatters = { "eslint_d", "eslint", stop_after_first = true }
  local terraform_formatters = { "terraform_fmt", "tofu_fmt", stop_after_first = true }
  conform.setup({
    formatters_by_ft = {
      go = { "gofmt" },
      hcl = terraform_formatters,
      javascript = js_formatters,
      javascriptreact = js_formatters,
      lua = { "stylua" },
      rust = { "rustfmt" },
      terraform = terraform_formatters,
      ["terraform-vars"] = terraform_formatters,
      typescript = js_formatters,
      typescriptreact = js_formatters,
    },
    format_on_save = function(bufnr)
      return vim.bo[bufnr].buftype == "" and { timeout_ms = 1200, lsp_format = "fallback" } or nil
    end,
  })
end

local lint = safe_require("lint")
if lint then
  local linters_by_ft = {}

  local function add_linter(ft, name)
    local linter = lint.linters[name]
    local cmd = type(linter) == "table" and linter.cmd or nil
    if type(cmd) == "function" then
      local ok, resolved = pcall(cmd)
      cmd = ok and resolved or nil
    end
    if type(cmd) == "string" and executable(cmd) then
      linters_by_ft[ft] = linters_by_ft[ft] or {}
      table.insert(linters_by_ft[ft], name)
    end
  end

  add_linter("go", "golangcilint")
  for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    add_linter(ft, "eslint_d")
    add_linter(ft, "eslint")
  end

  lint.linters_by_ft = linters_by_ft
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function()
      pcall(lint.try_lint)
    end,
  })
end

vim.diagnostic.config({
  float = { border = "rounded", source = "if_many" },
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
})

local diagnostic_group = vim.api.nvim_create_augroup("user.diagnostics", {})

local function update_diagnostic_loclist(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local win_config = vim.api.nvim_win_get_config(win)
    if win_config.relative == "" and vim.api.nvim_win_get_buf(win) == bufnr then
      pcall(vim.diagnostic.setloclist, { winnr = win, open = false, title = "Diagnostics" })
    end
  end
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
  group = diagnostic_group,
  callback = function(ev)
    update_diagnostic_loclist(ev.buf)
  end,
})

vim.api.nvim_create_autocmd("CursorHold", {
  group = diagnostic_group,
  callback = function()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    if #vim.diagnostic.get(0, { lnum = line }) > 0 then
      vim.diagnostic.open_float({ border = "rounded", focus = false, scope = "cursor", source = "if_many" })
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user.lsp", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end

    local function lsp_map(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, desc, { buffer = ev.buf })
    end
    lsp_map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    lsp_map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    lsp_map("n", "K", vim.lsp.buf.hover, "Show hover")
    lsp_map("i", "<C-Space>", vim.lsp.completion.get, "Trigger completion")
  end,
})

local servers = {
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
    workspace_required = true,
  },
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        runtime = { version = "LuaJIT" },
        workspace = { checkThirdParty = false },
      },
    },
  },
  ruby_lsp = {
    cmd = { "ruby-lsp" },
    filetypes = { "ruby", "eruby" },
    root_markers = { "Gemfile", ".git" },
    workspace_required = true,
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    workspace_required = true,
  },
  terraformls = {
    cmd = { "terraform-ls", "serve" },
    filetypes = { "terraform", "terraform-vars", "hcl" },
    root_markers = { ".terraform", ".git" },
    workspace_required = true,
  },
  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
    workspace_required = true,
  },
}

for name, config in pairs(servers) do
  if executable(config.cmd[1]) then
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

local function parse_file_line(name)
  for _, pattern in ipairs({ "^(.-):(%d+):(%d+):?$", "^(.-):(%d+):?$", "^(.-)%((%d+):?(%d*)%)$" }) do
    local file, line, col = name:match(pattern)
    if file and vim.fn.filereadable(file) == 1 then
      return file, tonumber(line), tonumber(col) or 1
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() ~= 1 then
      return
    end

    local original = vim.api.nvim_get_current_buf()
    local file, line, col = parse_file_line(vim.api.nvim_buf_get_name(original))
    if not file then
      return
    end

    vim.cmd.edit(vim.fn.fnameescape(file))
    pcall(vim.api.nvim_win_set_cursor, 0, { line, math.max(col - 1, 0) })
    vim.cmd("normal! zvzz")
    if vim.api.nvim_buf_is_valid(original) and original ~= vim.api.nvim_get_current_buf() then
      pcall(vim.api.nvim_buf_delete, original, { force = true })
    end
    vim.cmd("filetype detect")
  end,
})

vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "Review Neovim plugin updates" })
