local api = vim.api
local buf, win, border_buf, border_win
local position = 0

local function close_window()
	api.nvim_win_close(win, true)
end

-- Our file list start at line 4, so we can prevent reaching above it
-- from bottom the end of the buffer will limit movement
local function move_cursor()
	local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
	api.nvim_win_set_cursor(win, {new_pos, 0})
end

-- Open file under cursor
local function open_file()
	local str = api.nvim_get_current_line()
	close_window()
	api.nvim_command('edit '..str)
end

local function set_mappings()
	local mappings = {
		['['] = 'update_view(-1)',
		[']'] = 'update_view(1)',
		['<cr>'] = 'open_file()',
		h = 'update_view(-1)',
		l = 'update_view(1)',
		q = 'close_window()',
		k = 'move_cursor()'
	}

	for k,v in pairs(mappings) do
		api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"whid".'..v..'<cr>', {
			nowait = true, noremap = true, silent = true
		})
	end
end

local function center(str)
	local width = api.nvim_win_get_width(0)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(' ', shift) .. str
end

local function update_view(direction)
	-- Is nice to prevent user from editing interface, so
	-- we should enable it before updating view and disable it after
	api.nvim_buf_set_option(buf, 'modifiable', true)

	position = position + direction
	if position < 0 then position = 0 end -- HEAD~0 is the newest state

	-- we will use vim systemlist function which run shell
	-- command and return result as list
	local result = vim.fn.systemlist('git diff-tree --no-commit-id --name-only -r HEAD')

	-- with small indentation results will look better
	for k,v in pairs(result) do
		result[k] = ' '..result[k]
	end

	api.nvim_buf_set_lines(buf, 0, -1, false, {
		center('What have i done?'),
		center('HEAD~'..position),
		''
	})
	api.nvim_buf_set_lines(buf, 3, -1, false, result)

	api.nvim_buf_add_highlight(buf, -1, 'WhidHeader', 0, 0, -1)
	api.nvim_buf_add_highlight(buf, -1, 'WhidSubHeader', 1, 0, -1)

	api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function open_window()
	buf = api.nvim_create_buf(false, true) -- create new empty buffer
	border_buf = api.nvim_create_buf(false, true) -- create new empty buffer for border

	api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

	-- get dimensions
	local width = api.nvim_get_option("columns")
	local height = api.nvim_get_option("lines")

	-- calculate our floating window size
	local win_width = math.ceil(width * 0.8)
	local win_height = math.ceil(height * 0.8 - 4)

	-- and its starting position
	local col = math.ceil((width - win_width) / 2)
	local row = math.ceil((height - win_height) / 2 - 1)

	-- set some options
	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col
	}

	local border_opts = {
		style = "minimal",
		relative = "editor",
		width = win_width + 2,
		height = win_height + 2,
		row = row - 1,
		col = col - 1
	}

	local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
	local middle_line = '║' .. string.rep(' ', win_width) .. '║'
	for i = 1, win_height do
		table.insert(border_lines, middle_line)
	end
	table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')

	api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
	-- set buffer's (border_buf) lines from first line (0) to last (-1)
	-- ignoring out-of-bounds error (false) with lines (border_lines)

	-- and finally create it with buffer attached
	border_win = api.nvim_open_win(border_buf, true, border_opts)
	win = api.nvim_open_win(buf, true, opts)
	api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
end

local function whid()
	position = 0 -- if you want to preserve last displayed state just omit this line
	open_window()
	set_mappings()
	update_view(0)
	api.nvim_win_set_cursor(win, {4, 0}) -- set cursor on first line entry
end

return {
	whid = whid,
	update_view = update_view,
	open_file = open_file,
	move_cursor = move_cursor,
	close_window = close_window
}
