vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", ":Ex<CR>")
vim.keymap.set("n", "<", ":bp<CR>")
vim.keymap.set("n", ">", ":bn<CR>")
vim.keymap.set("n", "<leader>s", 'yiw:%s/<C-r>"//g<Left><Left>', { noremap = true })
vim.keymap.set("n", "<leader>=", "=ap", { noremap = true })
vim.keymap.set("n", "<C-n>", "<cmd>noh<CR>")
vim.keymap.set("i", "<ESC>", "<ESC>l")
vim.keymap.set("v", "<leader>S", [[y:echo eval(join(split(getreg('"')), '+'))<CR>]], { silent = true })

vim.keymap.set("i", "<C-l>", "<right>")
vim.keymap.set("i", "<C-h>", "<left>")
--
vim.keymap.set("n", "<C-o>", "<C-o>zz", { noremap = true })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { noremap = true })

vim.keymap.set("n", "G", "Gzz", { noremap = true })

vim.keymap.set("n", "a", "A", { noremap = true })
vim.keymap.set("n", "A", "a", { noremap = true })

vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })

vim.keymap.set("n", "v", "V", { noremap = true })
vim.keymap.set("n", "V", "v", { noremap = true })

vim.keymap.set("n", "S", "s", { noremap = true })
vim.keymap.set("n", "s", "S", { noremap = true })

vim.keymap.set("n", "<C-b>", "<cmd>bd<CR>")

-- Navgation
vim.keymap.set("n", "<C-j>", "<C-d>", { noremap = true })
vim.keymap.set("n", "<C-k>", "<C-u>", { noremap = true })
vim.cmd("vnoremap <C-j> 15j")
vim.cmd("vnoremap <C-k> 15k")

-- Editiing
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- command line mode keymap sugar
vim.keymap.set("v", "q:", "q:a")
vim.keymap.set("n", "q:", "q:a")

-- Auto correction
vim.keymap.set("n", "<leader>.", "z=")

-- PDF TJ Operator Formatter
vim.keymap.set("v", "<leader>t", function()
	-- 1. Exit visual mode to lock in the '< and '> marks
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

	-- 2. Grab the coordinates of the visual selection
	local s_pos = vim.fn.getpos("'<")
	local e_pos = vim.fn.getpos("'>")

	-- Neovim API uses 0-based indexing for rows/cols
	local s_row, s_col = s_pos[2] - 1, s_pos[3] - 1
	local e_row, e_col = e_pos[2] - 1, e_pos[3]

	-- 3. Extract the text
	local lines = vim.api.nvim_buf_get_text(0, s_row, s_col, e_row, e_col, {})
	local raw_text = table.concat(lines, " ")

	-- 4. Process the string: split by spaces and wrap in parentheses
	local words = {}
	for word in raw_text:gmatch("%S+") do
		table.insert(words, "(" .. word .. ")")
	end

	-- 5. Construct the final string and replace the old text in the buffer
	if #words > 0 then
		local formatted_text = "" .. table.concat(words, " -250 ") .. ""
		vim.api.nvim_buf_set_text(0, s_row, s_col, e_row, e_col, { formatted_text })
	end
end, { desc = "Convert selected text to PDF TJ format", noremap = true, silent = true })

--------------

-- Define the command to run on a visual selection
vim.api.nvim_create_user_command("CalcPdfWidth", function()
	-- 1. Grab the current visual selection
	local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
	local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
	local lines = vim.fn.getline(csrow, cerow)

	if #lines == 0 then
		return
	end

	-- If it's a single line, trim to the exact visual selection
	if #lines == 1 then
		lines[1] = string.sub(lines[1], cscol, cecol)
	end

	local input_string = table.concat(lines, " ")

	-- 2. The decoded Widths array mapping
	local char_widths = {
		["#"] = 44.611111,
		["$"] = 44.611111,
		["%"] = 68.722221,
		["&"] = 51.222229,
		["'"] = 22.388889,
		["("] = 30.111111,
		[")"] = 30.111111,
		["*"] = 37.388889,
		["+"] = 44.611111,
		[","] = 21.777781,
		["-"] = 29.277781,
		["."] = 21.111111,
		["/"] = 47.777779,
		["0"] = 44.611111,
		["1"] = 44.611111,
		["2"] = 44.611111,
		["3"] = 44.611111,
		["4"] = 44.611111,
		["5"] = 44.611111,
		["6"] = 44.611111,
		["7"] = 44.611111,
		["8"] = 44.611111,
		["9"] = 44.611111,
		[":"] = 21,
		[";"] = 21.777781,
		["<"] = 44.611111,
		["="] = 44.611111,
		[">"] = 44.611111,
		["?"] = 37.5,
		["@"] = 74,
		["A"] = 49.388889,
		["B"] = 48.111111,
		["C"] = 42.111111,
		["D"] = 51.611111,
		["E"] = 38.611111,
		["F"] = 37.611111,
		["G"] = 50.888889,
		["H"] = 51.222229,
		["I"] = 21.777781,
		["J"] = 22.277781,
		["K"] = 44.222229,
		["L"] = 35,
		["M"] = 65.611107,
		["N"] = 55.277779,
		["O"] = 52.777779,
		["P"] = 43.277779,
		["Q"] = 52.777779,
		["R"] = 45.111111,
		["S"] = 40.222229,
		["T"] = 35,
		["U"] = 50.5,
		["V"] = 45.222229,
		["W"] = 68.277779,
		["X"] = 42.388889,
		["Y"] = 42.277779,
		["Z"] = 38.111111,
		["["] = 49.388889,
		["\\"] = 48.277779,
		["]"] = 49.388889,
		["^"] = 0,
		["_"] = 44.611111,
		["`"] = 28.611111,
		["a"] = 41.888889,
		["b"] = 44.222229,
		["c"] = 35.888889,
		["d"] = 44.277779,
		["e"] = 44.388889,
		["f"] = 25.888889,
		["g"] = 44.222229,
		["h"] = 44.277779,
		["i"] = 20.111111,
		["j"] = 19.722219,
		["k"] = 40.388889,
		["l"] = 20.388889,
		["m"] = 69.611107,
		["n"] = 44.277779,
		["o"] = 44.5,
		["p"] = 44.277779,
		["q"] = 44.222229,
		["r"] = 27,
		["s"] = 34.611111,
		["t"] = 26.388889,
		["u"] = 43.722229,
		["v"] = 41.888889,
		["w"] = 65.611107,
		["x"] = 40.111111,
		["y"] = 42,
		["z"] = 34.722221,
	}

	local font_size = 9
	local total_width = 0

	-- 3. Parse and calculate the strings inside the parentheses
	for text_block in string.gmatch(input_string, "%((.-)%)") do
		for i = 1, #text_block do
			local char = text_block:sub(i, i)
			local char_w = char_widths[char] or 0

			-- New Formula: (Width / 100) * Font Size
			total_width = total_width + ((char_w / 100) * font_size)
		end
	end

	-- 4. Parse the numeric adjustments outside the parentheses
	local structure_only = string.gsub(input_string, "%(.-%)", " ")

	for num_str in string.gmatch(structure_only, "-?%d+%.?%d*") do
		local tj_value = tonumber(num_str)
		if tj_value then
			if tj_value == -250 then
				-- Hardcoded physical width for the -250 space adjustment
				total_width = total_width + 2.29201
			else
				-- Standard PDF TJ offset calculation fallback for other numbers
				local adjustment = (-tj_value / 1000) * font_size
				total_width = total_width + adjustment
			end
		end
	end

	-- 5. Output the result
	print(string.format("Input: %s | Width: %.4f pt", input_string, total_width))
end, { range = true })

-- Bind the command to <leader>c in visual mode
vim.keymap.set("v", "<leader>c", ":CalcPdfWidth<CR>", { noremap = true, desc = "Calculate PDF String Width" })

----------------------------------------------------------------

-- Helper function to format the number (e.g., 10000 -> 10,000.00)
local function format_financial(amount)
	-- Strip any accidental whitespace or newlines from the highlight
	local clean_amount = tostring(amount):gsub("[%s\n\r]", "")
	local num = tonumber(clean_amount)

	-- If the highlight isn't a valid number, just return the raw text
	if not num then
		return clean_amount
	end

	-- Force 2 decimal places
	local formatted = string.format("%.2f", num)

	-- Insert commas for thousands
	local left, digits, right = string.match(formatted, "^([^%d]*%d)(%d*)(.-)$")
	return left .. (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

-- Note the 'v' here, mapping this strictly to Visual mode
vim.keymap.set("v", "<leader>p", function()
	-- 1. Save the contents of register 'z' so we don't overwrite your data
	local saved_reg = vim.fn.getreg("z")
	local saved_type = vim.fn.getregtype("z")

	-- 2. Yank the current visual selection into register 'z'
	vim.cmd('normal! "zy')
	local raw_val = vim.fn.getreg("z")

	-- 3. Format the extracted number
	local formatted_val = format_financial(raw_val)

	-- 4. Construct the multiline PDF string (\n ensures clean formatting)
	local template = "BT\n/F11 9 Tf\n1 0 0 1 501.909 242.16 Tm\nTd (" .. formatted_val .. ")Tj\nET"

	-- 5. Load the constructed template into register 'z'
	vim.fn.setreg("z", template, "v")

	-- 6. Reselect the original visual area and paste over it
	vim.cmd('normal! gv"zp')

	-- 7. Restore register 'z' to its original state
	vim.fn.setreg("z", saved_reg, saved_type)
end, { noremap = true, silent = true, desc = "Replace visual selection with formatted PDF stream" })
