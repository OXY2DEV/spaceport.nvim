local M = {}

---@class (exact) SpaceportConfig
---@field ignoreDirs? string[]
---@field replaceHome? boolean
---@field projectEntry? string | fun()
local opts = {
	ignoreDirs = {},
	replaceHome = true,
	projectEntry = "Ex",
}
local startupStart = 0
local startupTime = 0

function M.timeStartup()
	startupStart = vim.loop.hrtime()
end

function M.timeStartupEnd()
	startupTime = vim.loop.hrtime() - startupStart
end

function M.getStartupTime()
	return startupTime / 1e6
end

local hasInit = false
---@param _opts SpaceportConfig
function M.setup(_opts)
	hasInit = true
	for k, v in pairs(_opts) do
		if not opts[k] then
			error("Invalid option for spaceport config: " .. k)
		end
		opts[k] = v
	end
end

function M._getHasInit()
	return hasInit
end
function M._getIgnoreDirs()
	return opts.ignoreDirs
end

function M._swapHomeWithTilde(path)
	if opts.replaceHome then
		if jit.os == "Windows" then
			return path:gsub(os.getenv("USERPROFILE"), "~")
		end
		return path:gsub(os.getenv("HOME"), "~")
	end
	return path
end

function M._fixDir(path)
	---@type string
	local ret = M._swapHomeWithTilde(path)
	for _, dir in pairs(opts.ignoreDirs) do
		local ok = type(dir) == "table"
		if ok then
			-- print(vim.inspect(d))
			ret = ret:gsub(dir[1], dir[2])
			-- return ret
		else
			ret = ret:gsub(dir, "")
		end
	end
	return ret
end

function M._projectEntryCommand()
	if type(opts.projectEntry) == "string" then
		vim.cmd(opts.projectEntry)
	elseif type(opts.projectEntry) == "function" then
		opts.projectEntry()
	end
end

return M
