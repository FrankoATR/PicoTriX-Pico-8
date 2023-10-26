pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

local cam_x, cam_y
local startPositionX, startPositionY
local game_objects
local game_over
local globalTime
local score
local combo
local next_objects
local deleteLineTime
local player
local game_over_text


local debug_aux = 0

function _init()
    
    cam_x, cam_y = 0,0
    startPositionX, startPositionY = 0,0
    game_objects = {}
    game_over = false
    globalTime = 0
	score = 0
	combo = 1
	next_objects = {}
	deleteLineTime = 0
	player = nil
	game_over_text = 0

	local x, y, sprite_id

	for y=0, 100 do
		for x=0, 100 do
			sprite_id = mget(x, y) 

			for i=1, 3 do
				if sprite_id == i then
					normal_block(x*8,y*8, i)
				end
			end

			if sprite_id == 4 then
				big_block(x*8,y*8, 4)
			end

			if sprite_id == 6 then
				mini_block(x*8,y*8, flr(rnd(4)))
			end

			for i=9, 15 do
				if sprite_id == i then
					background_block(x*8,y*8, i)
				end
			end
			for i=25, 29 do
				if sprite_id == i then
					background_block(x*8,y*8, i)
				end
			end

		end
	end


	player = player_hand()
	--camera(-8, -8)
end

function _update()

	if not game_over then
		local obj
		for obj in all(game_objects) do
			--if obj.x < cam_x+136 and obj.x > cam_x-16 and obj.y < cam_y+136 and obj.y-8 > cam_y-16 then
				obj:update()
			--end
		end
	
	
		if globalTime <= 1800 then  --Counting to 1 minute
			globalTime +=1
		else
			globalTime = 0
		end
	
		if globalTime%10 == 0 then
			--normal_block(flr(rnd(10)+1)*8, 0, flr(rnd(3)+1))
			for i=1, 10 do
				--normal_block(i*8, 0, flr(rnd(3)+1))
	
			end
		end
		if globalTime%60 == 0 then
			--normal_block(flr(rnd(10)+1)*8, 0, flr(rnd(3)+1))
				--normal_block(10*8, 0, flr(rnd(3)+1))
	
		end
	
		if globalTime%15 == 0 then
			verify_line_complete()
			verify_gameOver()
		end
	else
		game_over_text = flr(rnd(14)+1)

		for obj in all(game_objects) do
			if obj.name == "player" then
				del(game_objects, obj)
			end
		end

		del(game_objects, game_objects[flr(rnd(#game_objects)+1)])

	end



end

function _draw()
    cls()

    local obj
	for obj in all(game_objects) do
		if obj.x < cam_x+136 and obj.x > cam_x-16 and obj.y < cam_y+136 and obj.y-8 > cam_y-16 then
			obj:draw()
		end
	end

	display_game_info()

	--print(debug_aux, 15, 8)

end




function mini_block(x, y, sprite)
    return block("mini", x, y, 4, 4, sprite, true, {
		sprite = sprite,
		spx = flr(sprite/2),
		spy = sprite%2,
		update = function(self)
            self.velocity_y = 5
            if globalTime%10 == 0 then
                --self.y += self.velocity_y
            end
        end,
		draw = function(self)
			sspr(48+self.spx*4, 0+self.spy*4 , 4, 4  , self.x, self.y)
		end
    })
end

function normal_block(x, y, sprite)
    return block("normal", x, y, 8, 8, sprite, true, {
		velocity_y = 8,
		active = true,
		update = function(self)
			self.prev_x = self.x
			self.prev_y = self.y

			if self.active and globalTime%30 == 0 and not self.in_use then
				self.y += self.velocity_y
				self:check_collision_with_blocks()

			end

			if not self.alive then
				self:delete()
			end


        end,
		draw = function(self)
			spr(self.sprite, self.x, self.y)
			--print(self.y, self.x, self.y)

		end
    })
end

function big_block(x, y, sprite)
    return block("big", x, y, 16, 16, sprite, true, {
		update = function(self)
            --self.velocity_y = 5
            if globalTime%10 == 0 then
                --self.y += self.velocity_y
            end
        end,
		draw = function(self)
			spr(self.sprite, self.x, self.y, 2, 2)
		end
    })
end

function background_block(x, y, sprite)
    return block("background", x, y, 8, 8, sprite, true, {
		velocity_y = 0,
		active = false,
		update = function(self)
        end,
		draw = function(self)
			spr(self.sprite, self.x, self.y)
		end
    })
end

function block(category, x, y, w, h, sprite, collisions, props)
	local obj = make_game_object("block", x, y, {
        category = category,
		width = w,
		height = h,
		sprite = sprite,
		active = false,
		collisions = collisions,
		deleteTime = 0,
		alive = true,
		in_use = false,
        update = function(self)

        end,
		check_collision_with_blocks = function(self)
			if self.active then
				for_each_game_object("block",
				function(block)
					if block.collisions and not block.active and block != self then
						if self:check_for_hit(block) then

							if self.y != self.prev_y and not (self.x != self.prev_x ) then
								self.active = false
								player.actual_figure = nil
							end


							if self.x != self.prev_x then
								self.x = self.prev_x
							else
								self.y = self.prev_y
							end

						end
					end

				end
			)
			end

		end,
		delete = function(self)
			self.deleteTime += 1
			if(self.deleteTime == 3) then
				self.sprite = 56
			elseif(self.deleteTime == 6) then
				self.sprite = 55
			elseif(self.deleteTime == 9) then
				del(game_objects, self)
				for_each_game_object("block",
				function(block)
		
					if(not block.active and block.category != "background" and block.x == self.x and block.y <= self.y) then
						block.y += 8
					end
				end
				)
			end
		end
	})
	local key, value
	for key, value in pairs(props) do
		obj[key] = value
	end
	return obj
end



function make_game_object(name, x, y, props)
	local obj = {
		name = name,
		x = x,
		y = y,
		prev_x = 0,
		prev_y = 0,
		velocity_x = 0,
		velocity_y = 0,
		collisions = true,
		update = function(self)
		end,
		draw = function(self)
		end,
		draw_bounding_box = function(self, color)
			rect(self.x, self.y, self.x+self.width-1, self.y+self.height-1, color)
		end,
		center = function(self)
			return self.x+self.width/2, self.y+self.height/2
		end,
		check_for_hit = function(self, other)
			return bounding_boxes_overlapping(self, other)
		end,
		check_for_collision = function(self, other, indent)
			local x,y,w,h = self.x, self.y, self.width, self.height
			local t_h = { x = x+indent, y = y, width = w-2*indent, height = h/2	}
			local b_h = { x = x+indent, y = y + h/2, width = w-2*indent, height = h/2 }
			local l_h = { x = x, y = y+indent, width = w/2, height = h-2*indent	}
			local r_h = { x = x + w/2, y = y+indent, width = w/2, height = h-2*indent }
			
			if bounding_boxes_overlapping(b_h, other) then
				return "down"
			elseif bounding_boxes_overlapping(t_h, other) then
				return "up"
			elseif bounding_boxes_overlapping(l_h, other) then
				return "left"
			elseif bounding_boxes_overlapping(r_h, other) then
				return "right"
			end

		end,
		handle_collision = function(self, other, dir)
			if dir == "down"then
				self.y = other.y - self.height
				if self.velocity_y > 0 then 
					self.velocity_y = 0
				end
			elseif dir == "up" then
				self.y = other.y + other.height
				if self.velocity_y < 0 then 
					self.velocity_y = 0
				end
			elseif dir == "left" then
				self.x = other.x + other.width
				if self.velocity_x < 0 then 
					self.velocity_x = 0
				end
			elseif dir == "right" then
				self.x = other.x - self.width
				if self.velocity_x > 0 then 
					self.velocity_x = 0
				end
			end
		end
	}
	local key, value
	for key, value in pairs(props) do
		obj[key] = value
	end

	add(game_objects, obj)

	return obj
end

function verify_line_complete()
	local linesToDetele = 0
	combo = 1

	for i=0, 14 do
		local y = i*8
		local line_blocks = {}

		for_each_game_object("block",
			function(block)

				if(block.alive and not block.active and block.category != "background" and y == block.y) then
					add(line_blocks, block)
				end
			end	
		)

		if #line_blocks == 10 then
			delete_line_complete(line_blocks)
			line_blocks = {}
			linesToDetele += 1
		end

	end

	--debug_aux = linesToDetele

	if linesToDetele > 0 then
		combo += 0.5*(linesToDetele-1)
		score += 200*combo*linesToDetele
	end

end


function delete_line_complete(line_blocks)
	for i = 1, 10 do
		line_blocks[i].alive = false
	end
end




function verify_gameOver()

	for_each_game_object("block",
		function(block)
			if(block.alive and not block.active and block.category != "background" and block.y <=0) then
				game_over = true
			end
		end	
	)

end


function player_hand()
	return make_game_object("hand", 5*8, 0, {
		actual_figure = nil,
		velocity_x = 8,
		velocity_y = 8,
		hold = nil,

		update = function(self)

			if(not self.actual_figure) then
				self.actual_figure = normal_block(5*8, 0, flr(rnd(3)+1))
			end

			if btn(0) then
				if globalTime%3 == 0 then
					self.velocity_x = -8
					self.actual_figure.x += self.velocity_x
				end
			end
			if btn(1) then
				if globalTime%3 == 0 then
					self.velocity_x = 8
					self.actual_figure.x += self.velocity_x

				end
			end

			if btn(3) then
				self.actual_figure.in_use = true
				if globalTime%3 == 0 then
					self.actual_figure.y += self.velocity_y
				end
			else
				self.actual_figure.in_use = false
			end


			if btn(4) then
				if globalTime%5 == 0 then
					while self.actual_figure do
						self.actual_figure.prev_y = self.actual_figure.y
						self.actual_figure.prev_x = self.actual_figure.x
	
						self.actual_figure.y += self.velocity_y
						self.actual_figure:check_collision_with_blocks()
					end				
				end

			end
			
			if self.actual_figure then
				self.actual_figure:check_collision_with_blocks()
			end


		end

	})

end

function display_game_info()

	print("score ", 96, 10)
	print(score, 96, 18)

	if not game_over then
		print("next ", 96, 30)
	
		print("combo ", 96, 100)
		print("x", 96, 108)
	
		print(combo, 100, 108)
	else
		print("game over noob", 3*8-4, 6*8, game_over_text)
	end

end


function rects_overlapping(l1, t1, r1, b1, l2, t2, r2, b2)
	return r1 > l2 and r2 > l1 and b1 > t2 and b2 > t1
end

function bounding_boxes_overlapping(obj1, obj2)
	return rects_overlapping(obj1.x, obj1.y, obj1.x+obj1.width, obj1.y+obj1.height, obj2.x, obj2.y, obj2.x+obj2.width, obj2.y+obj2.height)
end


function for_each_game_object(name, callback)
	local obj

	for obj in all(game_objects) do

		if obj.name == name then
			callback(obj)
		end
	
	end
end

__gfx__
000000006dddddd6abbbbbba488888841111111111111111121176770000000000000000cccccccccc000000cccccccc00000000000000cccccccccccccccccc
00000000deeeeeedb999999b855555581721222222222711220166070000000000000000cccccccccc000000cccccccc00000000000000cccccccccccccccccc
00700700deeeeeedb999999b855555581272211122112111102270660000000000000000cc0000cccc0000000000000000000000000000cccc000000000000cc
00077000deeeeeedb999999b855555581212211122227211112177670000000000000000cc0000cccc0000000000000000000000000000cccc000000000000cc
00077000deeeeeedb999999b855555581212122111112121abaa45440000000000000000cc0000cccc0000000000000000000000000000cccc000000000000cc
00700700deeeeeedb999999b855555581212122212212121bb0a55040000000000000000cc0000cccc0000000000000000000000000000cccc000000000000cc
00000000deeeeeedb999999b855555581211212111222221a0bb40550000000000000000cc0000cccc00000000000000cccccccc000000cccc000000000000cc
000000006dddddd6abbbbbba488888841221212121111221aaba44540000000000000000cc0000cccc00000000000000cccccccc000000cccc000000000000cc
000000006d6600d7a40424b2418600811121212221121122000000000000000000000000cc0000cccc0000cc000000cccccccccccc0000000000000000000000
00000000df0e777d29240294656561561121222121222121000000000000000000000000cc0000cccc0000cc000000cccccccccccc0000000000000000000000
00000000770fe70fb22b9342151654541122212122212122000000000000000000000000cc0000cccc000000000000cc00000000000000000000000000000000
000000007eef7e604044394b805556001121212212212222000000000000000000000000cc0000cccc000000000000cc00000000000000000000000000000000
00000000dfee067fb2490403001514501121222222112211000000000000000000000000cc0000cccc000000000000cc00000000000000000000000000000000
000000000e60efed02923424045615681221711222112171000000000000000000000000cc0000cccc000000000000cc00000000000000000000000000000000
00000000677e77ef4922b92b411500411172222212222721000000000000000000000000cc0000cccccccccccccccccccccccccccccccccc0000000000000000
000000006760d0d63b3b04b3618608111111111111111111000000000000000000000000cc0000cccccccccccccccccccccccccccccccccc0000000000000000
000000006d6000d7a00000000006008010211201907997098058850800000000000000000000000011111111111111116eeee66ede66edd66eeee66ede66edd6
000000000000707d0924020465006000021dd120079aa9700584485000000000000000000000000022222222222222226deee66dde66dee66deee66dde66dee6
000000007000e00fb0200302151000542121121279799797585885850000000000000000000000006ede66eeee66eee66eed66eee66eeee66eed66eee66eeee6
000000007e000e004040304b005006001d1e21d19a9b79a9848318480000000000000000000000006ed66eeed666dde6eeee66eee66eee66eeee66eee66eee66
00000000d00e000fb0000003000000501d12e1d19a97b9a984813848000000000000000000000000eee66edee66eee66eed66eed666ede66eed66eed666ede66
000000000060e0000000042404061068212112127979979758588585000000000000000000000000ed66eeeed66ee666eee66eed66eeee66eee66eed66eeee66
00000000607e70004900b00b40050041021dd120079aa97005844850000000000000000000000000ee66eeeee66ee66edee66eee66ede66edee66eee66ede66e
00000000606000d0000b040360860001102112019079970980588508000000000000000000000000ed66dedd66dd666dede66ede66eee66eede66ede66eee66e
000000006d0000d7a0000000000600806dddddd6abbbbbba48888884c777777cc666666c00000000d66dddde66ed66dded66eeed66edd66eed66eeed66edd66e
000000000000007d0004020400006000deeeeeedb999999b85555558766666676777777600000000e66eedee66ee66eeee66ede66eeee66eee66ede66eeee66e
0000000070000000b020000200000004de6777edb999999b8555555876666667677777760000000066edeee66ee66eeed66eeee66eee66eed66eeee66eee66ee
00000000000000000000000000000000de6777edb999999b8555555876666667677777760000000066eeee66ede66edde66eeee66eee66eee66eeee66eee66ee
000000000000000f0000000000000000de6677edb999999b855555587666666767777776000000006edeee66dde66de6d66dedd66dd666ded66dedd66dd666de
00000000000000000000000004061000dee66eedb999999b855555587666666767777776000000006eeed66eee66eee666dddd66eed66ddd66dddd66eed66ddd
00000000007000000000b00000050001deeeeeedb999999b85555558766666676777777600000000222222222222222266eede66eee66eee66eede66eee66eee
00000000000000d0000b0403600000016dddddd6abbbbbba48888884c777777cc666666c0000000011111111111111116edeee66ee66eee66edeee66ee66eee6
__map__
09000000000000000000000e0b0b0b0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
19000000000000000000000a0000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1c1c1c1c1c1c1c1c1c1c1d0c0c0c1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
