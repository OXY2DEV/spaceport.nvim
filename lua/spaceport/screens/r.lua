local con = require("spaceport").getConfig();
local icons = con.icons ~= nil and con.icons or {};
local totalHistory = con.historySize ~= nil and con.historySize or 10;
local signCol = con.signCol ~= nil and con.signCol or { today = {}, yesterday = {}, pastWeek = {}, pastMonth = {}, later = {} };

local utils = require("spaceport.utils");
local dats = require("spaceport.data");

local links = {};
local top = con.top ~= nil and con.top or 7;

local makeGrad = function(from, to)
	local _cR = math.abs((from[1] - to[1]) / totalHistory);
	local _cG = math.abs((from[2] - to[2]) / totalHistory);
	local _cB = math.abs((from[3] - to[3]) / totalHistory);

	local colors = {};

	local _r = from[1];
	local _g = from[2];
	local _b = from[3];

	for i = 1, totalHistory, 1 do
		table.insert(colors, string.format("#%02X%02X%02X", math.floor(_r), math.floor(_g), math.floor(_b)));

		_r = _r - _cR;
		_g = _g - _cG;
		_b = _b - _cB;
	end

	return colors;
end

local textCol = con.textCol ~= nil and makeGrad(con.textCol[1], con.textCol[2]) or makeGrad({ 186, 194, 222 }, { 88, 91, 112 });




local rNew = function()
	local data = require("spaceport.data").getMruData();
	local _maxL = 1;

	local _out = {};

	for i = 1, totalHistory, 1 do
		local text = vim.fs.basename(data[i].prettyDir);
		local len = #text;

		if len > _maxL then
			_maxL = len;
		end
	end

	local title = " Recent Files "

	--table.insert(_out, { { string.rep("", 10), { fg = textCol[-1] } }, { title }, { string.rep("", 10) } })

	for n = 1, totalHistory, 1 do
		local text = vim.fs.basename(data[n].prettyDir)
		local line = {};
		local hasIcon = false;

		links[n + top] = data[n].dir;

		if utils.isToday(data[n].time) then
			table.insert(line, { "  ", colorOpts = signCol.today } );
		elseif utils.isYesterday(data[n].time) then
			table.insert(line, { "  ", colorOpts = signCol.yesterday } );
		elseif utils.isPastWeek(data[n].time) then
			table.insert(line, { "  ", colorOpts = signCol.pastWeek } );
		elseif utils.isPastMonth(data[n].time) then
			table.insert(line, { "  ", colorOpts = signCol.pastMonth } );
		else
			table.insert(line, { "  ", colorOpts = signCol.later } );
		end

		for _,item in ipairs(icons) do
			local pattern = item[1];
			local icon = item[2];
			local fg = item[3] ~= nil and item[3] or { fg = "#00ff00" };


			if string.match(text, pattern) ~= nil then
				table.insert(line, { icon, colorOpts = fg });
				hasIcon = true
			end
		end

		if hasIcon == false then
			table.insert(line, { " " });
		end

		table.insert(line, { text, colorOpts = { fg = textCol[n] } });

		local empty = ((vim.api.nvim_win_get_width(0) * 0.6) + (_maxL - #text - #tostring(n)));
	  table.insert(line, { string.rep(" ", empty)});

		table.insert(line, { tostring(n), colorOpts = { fg = textCol[#textCol - n] } });

		table.insert(_out, line);
	end

	return _out;
end

local mappings = {
	{
		mode = "n",
		key = "p",
		description = "Select Entry",
		action = function()
			local cursor = vim.api.nvim_win_get_cursor(0);
			local mru = dats.getMruData();

			local y = cursor[1];
			local x = cursor[2];
			if links[y] ~= nil then
				dats.cd(mru[y - top]);
			end
		end
	},
	{
		mode = "n",
		key = "d",
		description = "Delete Entry",
		action = function()
			local cursor = vim.api.nvim_win_get_cursor(0);
			local mru = dats.getMruData();

			local y = cursor[1];
			local x = cursor[2];
			if links[y] ~= nil then
				dats.removeDir(links[y]);

				require("spaceport.screen").render();
			end
		end
	}
}


return {
	lines = rNew,
  remaps = mappings,
  title = nil,
  topBuffer = 1,
} 
