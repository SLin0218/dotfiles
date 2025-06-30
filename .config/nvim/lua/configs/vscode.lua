local comment = {
  selected = function()
    require("vscode").action("editor.action.commentLine", {
      range = { vim.fn.line "v", vim.fn.line "." - 1 },
    })
  end,
}

local file = {
  new = function()
    require("vscode").action "workbench.explorer.fileView.focus"
    require("vscode").action "explorer.newFile"
  end,

  save = function()
    require("vscode").action "workbench.action.files.save"
  end,

  saveAll = function()
    require("vscode").action "workbench.action.files.saveAll"
  end,

  format = function()
    require("vscode").action "editor.action.formatDocument"
  end,

  showInExplorer = function()
    require("vscode").action "workbench.files.action.showActiveFileInExplorer"
  end,

  rename = function()
    require("vscode").action "workbench.files.action.showActiveFileInExplorer"
    require("vscode").action "renameFile"
  end,
}

local error = {
  list = function()
    require("vscode").action "workbench.actions.view.problems"
  end,
  next = function()
    require("vscode").action "editor.action.marker.next"
  end,
  previous = function()
    require("vscode").action "editor.action.marker.prev"
  end,
}

local editor = {
  closeActive = function()
    require("vscode").action "workbench.action.closeActiveEditor"
  end,

  closeOther = function()
    require("vscode").action "workbench.action.closeOtherEditors"
  end,

  organizeImport = function()
    require("vscode").action "editor.action.organizeImports"
  end,

  nextChange = function()
    require("vscode").action "workbench.action.editor.nextChange"
  end,

  previousChange = function()
    require("vscode").action "workbench.action.editor.previousChange"
  end,
}

local workbench = {
  showCommands = function()
    require("vscode").action "workbench.action.showCommands"
  end,
  previousEditor = function()
    require("vscode").action "workbench.action.previousEditor"
  end,
  nextEditor = function()
    require("vscode").action "workbench.action.nextEditor"
  end,
}

local toggle = {
  toggleActivityBar = function()
    require("vscode").action "workbench.action.toggleActivityBarVisibility"
  end,
  toggleSideBarVisibility = function()
    require("vscode").action "workbench.action.toggleSidebarVisibility"
  end,
  toggleZenMode = function()
    require("vscode").action "workbench.action.toggleZenMode"
  end,
  theme = function()
    require("vscode").action "workbench.action.selectTheme"
  end,
}

local symbol = {
  rename = function()
    require("vscode").action "editor.action.rename"
  end,
}

-- if bookmark extension is used
local bookmark = {
  toggle = function()
    require("vscode").action "bookmarks.toggle"
  end,
  list = function()
    require("vscode").action "bookmarks.list"
  end,
  previous = function()
    require("vscode").action "bookmarks.jumpToPrevious"
  end,
  next = function()
    require("vscode").action "bookmarks.jumpToNext"
  end,
}

local search = {
  reference = function()
    require("vscode").action "editor.action.referenceSearch.trigger"
  end,
  referenceInSideBar = function()
    require("vscode").action "references-view.find"
  end,
  project = function()
    require("vscode").action "editor.action.addSelectionToNextFindMatch"
    require("vscode").action "workbench.action.findInFiles"
  end,
  text = function()
    require("vscode").action "workbench.action.findInFiles"
  end,
}

local project = {
  findFile = function()
    require("vscode").action "workbench.action.quickOpen"
  end,
  switch = function()
    require("vscode").action "workbench.action.openRecent"
  end,
  tree = function()
    require("vscode").action "workbench.view.explorer"
  end,
}

local git = {
  init = function()
    require("vscode").action "git.init"
  end,
  status = function()
    require("vscode").action "workbench.view.scm"
  end,
  switch = function()
    require("vscode").action "git.checkout"
  end,
  deleteBranch = function()
    require("vscode").action "git.deleteBranch"
  end,
  push = function()
    require("vscode").action "git.push"
  end,
  pull = function()
    require("vscode").action "git.pull"
  end,
  fetch = function()
    require("vscode").action "git.fetch"
  end,
  commit = function()
    require("vscode").action "git.commit"
  end,
  publish = function()
    require("vscode").action "git.publish"
  end,

  -- if gitlens installed
  graph = function()
    require("vscode").action "gitlens.showGraphPage"
  end,
}

local fold = {
  toggle = function()
    require("vscode").action "editor.toggleFold"
  end,

  all = function()
    require("vscode").action "editor.foldAll"
  end,
  openAll = function()
    require("vscode").action "editor.unfoldAll"
  end,

  close = function()
    require("vscode").action "editor.fold"
  end,
  open = function()
    require("vscode").action "editor.unfold"
  end,
  openRecursive = function()
    require("vscode").action "editor.unfoldRecursively"
  end,

  blockComment = function()
    require("vscode").action "editor.foldAllBlockComments"
  end,

  allMarkerRegion = function()
    require("vscode").action "editor.foldAllMarkerRegions"
  end,
  openAllMarkerRegion = function()
    require("vscode").action "editor.unfoldAllMarkerRegions"
  end,
}

local vscode = {
  focusEditor = function()
    require("vscode").action "workbench.action.focusActiveEditorGroup"
  end,
  moveSideBarRight = function()
    require("vscode").action "workbench.action.moveSideBarRight"
  end,
  moveSideBarLeft = function()
    require("vscode").action "workbench.action.moveSideBarLeft"
  end,
}

local refactor = {
  showMenu = function()
    require("vscode").action "editor.action.refactor"
  end,
}

-- https://vi.stackexchange.com/a/31887
local nv_keymap = function(lhs, rhs)
  vim.api.nvim_set_keymap("n", lhs, rhs, { noremap = true, silent = true })
  vim.api.nvim_set_keymap("v", lhs, rhs, { noremap = true, silent = true })
end

local nx_keymap = function(lhs, rhs)
  vim.api.nvim_set_keymap("n", lhs, rhs, { silent = true })
  vim.api.nvim_set_keymap("v", lhs, rhs, { silent = true })
end

--#region keymap
vim.g.mapleader = " "

nv_keymap("s", "}")
nv_keymap("S", "{")

nv_keymap("<leader>h", "^")
nv_keymap("<leader>l", "$")
nv_keymap("<leader>a", "%")

nx_keymap("j", "gj")
nx_keymap("k", "gk")

vim.keymap.set({ "n", "v" }, "<leader>/", comment.selected)

vim.keymap.set({ "n" }, "<leader>i", editor.organizeImport)

-- no highlight
vim.keymap.set({ "n" }, "<leader>n", "<cmd>noh<cr>")

vim.keymap.set({ "n", "v" }, "<leader> ", workbench.showCommands)

vim.keymap.set({ "n", "v" }, "H", workbench.previousEditor)
vim.keymap.set({ "n", "v" }, "L", workbench.nextEditor)

-- error
vim.keymap.set({ "n" }, "<leader>el", error.list)
vim.keymap.set({ "n" }, "<leader>en", error.next)
vim.keymap.set({ "n" }, "<leader>ep", error.previous)

-- git
vim.keymap.set({ "n" }, "<leader>gb", git.switch)
vim.keymap.set({ "n" }, "<leader>gi", git.init)
vim.keymap.set({ "n" }, "<leader>gd", git.deleteBranch)
vim.keymap.set({ "n" }, "<leader>gf", git.fetch)
vim.keymap.set({ "n" }, "<leader>gs", git.status)
vim.keymap.set({ "n" }, "<leader>gp", git.pull)
vim.keymap.set({ "n" }, "<leader>gg", git.graph)

-- project
vim.keymap.set({ "n" }, "<leader>pf", project.findFile)
vim.keymap.set({ "n" }, "<leader>pp", project.switch)
vim.keymap.set({ "n" }, "<leader>pt", project.tree)

-- file
vim.keymap.set({ "n", "v" }, "<space>w", file.save)
vim.keymap.set({ "n", "v" }, "<space>wa", file.saveAll)
vim.keymap.set({ "n", "v" }, "<space>fs", file.save)
vim.keymap.set({ "n", "v" }, "<space>fS", file.saveAll)
vim.keymap.set({ "n" }, "<space>fm", file.format)
vim.keymap.set({ "n" }, "<space>fn", file.new)
vim.keymap.set({ "n" }, "<space>ft", file.showInExplorer)
vim.keymap.set({ "n" }, "<space>fr", file.rename)

-- buffer/editor
vim.keymap.set({ "n", "v" }, "<leader>x", editor.closeActive)
vim.keymap.set({ "n", "v" }, "<space>bc", editor.closeActive)
vim.keymap.set({ "n", "v" }, "<space>k", editor.closeOther)
vim.keymap.set({ "n", "v" }, "<space>bk", editor.closeOther)
vim.keymap.set({ "n", "v" }, "<space>vp", editor.previousChange)
vim.keymap.set({ "n", "v" }, "<space>vn", editor.nextChange)

-- toggle
vim.keymap.set({ "n", "v" }, "<leader>ta", toggle.toggleActivityBar)
vim.keymap.set({ "n", "v" }, "<leader>tz", toggle.toggleZenMode)
vim.keymap.set({ "n", "v" }, "<leader>ts", toggle.toggleSideBarVisibility)
vim.keymap.set({ "n", "v" }, "<leader>tt", toggle.theme)

-- refactor
vim.keymap.set({ "v" }, "<leader>r", refactor.showMenu)
vim.keymap.set({ "n" }, "<leader>rr", symbol.rename)
vim.api.nvim_set_keymap("n", "<leader>rd", "V%d", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>rv", "V%", { silent = true })

-- bookmark
vim.keymap.set({ "n" }, "<leader>m", bookmark.toggle)
vim.keymap.set({ "n" }, "<leader>mt", bookmark.toggle)
vim.keymap.set({ "n" }, "<leader>ml", bookmark.list)
vim.keymap.set({ "n" }, "<leader>mn", bookmark.next)
vim.keymap.set({ "n" }, "<leader>mp", bookmark.previous)

vim.keymap.set({ "n" }, "<leader>sr", search.reference)
vim.keymap.set({ "n" }, "<leader>sR", search.referenceInSideBar)
vim.keymap.set({ "n" }, "<leader>sp", search.project)
vim.keymap.set({ "n" }, "<leader>st", search.text)

-- vscode
vim.keymap.set({ "n" }, "<leader>ve", vscode.focusEditor)
vim.keymap.set({ "n" }, "<leader>vl", vscode.moveSideBarLeft)
vim.keymap.set({ "n" }, "<leader>vr", vscode.moveSideBarRight)

--folding
-- vim.keymap.set({ "n" }, "<leader>zr", fold.openAll)
-- vim.keymap.set({ "n" }, "<leader>zO", fold.openRecursive)
-- vim.keymap.set({ "n" }, "<leader>zo", fold.open)
-- vim.keymap.set({ "n" }, "<leader>zm", fold.all)
-- vim.keymap.set({ "n" }, "<leader>zb", fold.blockComment)
-- vim.keymap.set({ "n" }, "<leader>zc", fold.close)
-- vim.keymap.set({ "n" }, "<leader>zg", fold.allMarkerRegion)
-- vim.keymap.set({ "n" }, "<leader>zG", fold.openAllMarkerRegion)
-- vim.keymap.set({ "n" }, "<leader>za", fold.toggle)
--
-- vim.keymap.set({ "n" }, "zr", fold.openAll)
-- vim.keymap.set({ "n" }, "zO", fold.openRecursive)
-- vim.keymap.set({ "n" }, "zo", fold.open)
-- vim.keymap.set({ "n" }, "zm", fold.all)
-- vim.keymap.set({ "n" }, "zb", fold.blockComment)
-- vim.keymap.set({ "n" }, "zc", fold.close)
-- vim.keymap.set({ "n" }, "zg", fold.allMarkerRegion)
-- vim.keymap.set({ "n" }, "zG", fold.openAllMarkerRegion)
-- vim.keymap.set({ "n" }, "za", fold.toggle)
--#endregion keymap

vim.o.relativenumber = true
vim.o.clipboard = "unnamedplus"
