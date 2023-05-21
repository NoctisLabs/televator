--[[
MIT License
Copyright (c) 2017 Elijah Duffy
Copyright (c) 2019 Noctis Labs
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

-- an_televator/init.lua

string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end

local delay = {}
local itemset
if minetest.get_modpath("default") then
	itemset = {
		steel = "default:steel_ingot",
		gold = "default:gold_ingot",
		copper = "default:copper_ingot",
		glass = "default:glass",
		diamond = "default:diamond",
	}
end

if minetest.get_modpath("mcl_core") then
	itemset = {
		steel = "mcl_core:iron_ingot",
		gold = "mcl_core:gold_ingot",
		copper = "mcl_copper:copper_ingot",
		glass = "mcl_core:glass",
		diamond = "mcl_core:diamond",
	}
end

---
--- Functions
---

local function is_safe(pos)
	for i = 0, 1 do
		local tpos = vector.new(pos)
		tpos.y = tpos.y + i
		if minetest.get_node(tpos).name ~= "air" then
			return
		end
	end
	return true
end

local function get_near_televators(pos, which, range)
	for i = 1, range do
		local cpos = vector.new(pos)
		if which == "above" then
			cpos.y = cpos.y + i
		elseif which == "below" then
			cpos.y = cpos.y - i
		end
		local name = minetest.get_node(cpos).name
		if (which == "above" and tostring(name):startswith('an_televator:televator'))
				or (which == "below" and i ~= 1 and tostring(name):startswith('an_televator:televator')) then
			cpos.y = cpos.y + 1
			if is_safe(cpos) then
				return cpos
			end
		end
	end
end

---
--- Registrations
---

minetest.register_node("an_televator:televator", {
	description = "Televator",
	tiles = {"televator_televator.png"},
	groups = {cracky = 2, disable_jump = 1, pickaxey= 2 },
})

if itemset then
	minetest.register_craft({
		output = "an_televator:televator",
		recipe = {
			{itemset.steel, itemset.glass, itemset.steel},
			{itemset.steel, itemset.gold, itemset.steel},
			{itemset.steel, itemset.copper, itemset.steel,}
		},
	})
end

minetest.register_node("an_televator:televator_dia", {
	description = "Diamond televator",
	tiles = {"televator_televator_dia.png"},
	groups = {cracky = 2, disable_jump = 1, pickaxey= 2 },
})

if itemset then
	minetest.register_craft({
		output = "an_televator:televator_dia",
		recipe = {
			{itemset.steel, itemset.diamond, itemset.steel},
			{itemset.diamond, itemset.gold, itemset.diamond},
			{itemset.steel, itemset.diamond, itemset.steel,}
		},
	})
end

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pos  = player:get_pos()
		local name = player:get_player_name()
		if not delay[name] then
			delay[name] = 0.5
		else
			delay[name] = delay[name] + dtime
		end
		if not delay[name] or delay[name] > 0.5 then
			local nodename = tostring(minetest.get_node({x = pos.x, y = pos.y - 0.5, z = pos.z}).name)
			if nodename:startswith('an_televator:televator') then
				local where
				local controls = player:get_player_control()
				if controls.jump then
					where = "above"
				elseif controls.sneak then
					where = "below"
				else return end
					
				if nodename == 'an_televator:televator_dia' then
					local epos = get_near_televators(pos, where, 256)
				else
					local epos = get_near_televators(pos, where, 64)
				end
				
				if epos then
					player:set_pos(epos)
					minetest.sound_play("televator_whoosh", {
						gain = 0.75,
						pos = epos,
						max_hear_distance = 5,
					})
				else
					minetest.sound_play("televator_error", {
						gain = 0.75,
						pos = epos,
						max_hear_distance = 5,
					})
				end
				delay[name] = 0
			end
		end
	end
end)
