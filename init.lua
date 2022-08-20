local o = vim.o    --vim global options
local wo = vim.wo  --vim window-local options
local bo = vim.bo  --vim buffer-local options

-- global options
o.hlsearch = true
o.ignorecase = false

-- window-local options
wo.number = true
wo.relativenumber = true

local ok,_ = pcall(require, 'life')
if not ok then
	-- not loaded
	print('life failed to load')
end

