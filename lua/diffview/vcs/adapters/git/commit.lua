local lazy = require("diffview.lazy")
local oop = require('diffview.oop')

local Commit = lazy.access("diffview.vcs.commit", "Commit") ---@type Commit|LazyModule
local RevType = lazy.access("diffview.vcs.rev", "RevType") ---@type ERevType|LazyModule
local utils = lazy.require("diffview.utils") ---@module "diffview.utils"

local M = {}


---@class GitCommit : Commit
---@field hash string
---@field author string
---@field time number
---@field time_offset number
---@field date string
---@field rel_date string
---@field ref_names string
---@field subject string
---@field body string
local GitCommit = oop.create_class("GitCommit", Commit.__get())

function GitCommit:init(opt)
  GitCommit:super().init(self, opt)
end

---@param rev_arg string
---@param adapter GitAdapter
---@return GitCommit?
function GitCommit.from_rev_arg(rev_arg, adapter)
  local out, code = adapter:exec_sync({
    "show",
    "--pretty=format:%H %P%n%an%n%ad%n%ar%n  %s",
    "--date=raw",
    "--name-status",
    rev_arg,
    "--",
  }, adapter.ctx.toplevel)

  if code ~= 0 then
    return
  end

  local right_hash, _, _ = unpack(utils.str_split(out[1]))
  local time, time_offset = unpack(utils.str_split(out[3]))

  return GitCommit({
    hash = right_hash,
    author = out[2],
    time = tonumber(time),
    time_offset = time_offset,
    rel_date = out[4],
    subject = out[5]:sub(3),
  })
end

---@param rev Rev
---@param adapter GitAdapter
---@return GitCommit?
function GitCommit.from_rev(rev, adapter)
  assert(rev.type == RevType.COMMIT, "Rev must be of type COMMIT!")

  return GitCommit.from_rev_arg(rev.commit, adapter)
end

function GitCommit.parse_time_offset(iso_date)
  local sign, h, m = vim.trim(iso_date):match("([+-])(%d%d):?(%d%d)$")
  local offset = tonumber(h) * 60 * 60 + tonumber(m) * 60

  if sign == "-" then
    offset = -offset
  end

  return offset
end

M.GitCommit = GitCommit
return M
