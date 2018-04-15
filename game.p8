pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

t = 0
state = 0

function goto_game()
  state = 1
  t = 0
end

function goto_logo()
  state = 0
  t = 0
end

function goto_game_over(r)
  game_over_reason = r
  state = 2
  t = 0
end

function _update60()
  t = t+1
  if state == 0 then
    logo_upd()
  elseif state == 1 then
    background_upd()
    map_upd()
    ship_upd()
    hud_upd()
  elseif state == 2 then
    game_over_upd()
  end
end

function _draw()
  cls()
  if state == 0 then
    logo_draw()
  elseif state == 1 then
    background_draw()
    map_draw()
    ship_draw()
    hud_draw()
  elseif state == 2 then
    game_over_draw()
  end
end
-->8
// ship
ship = {
  sp_width = 3,
  sp_height = 2,
  x = 11,
  y = 60,
  sp = 0,
  fuel = 100,
  box_rel = {
    x = 0,
    y = 14,
    w = 22,
    h = 2
  }
}

function ship_apply_item(item)
  if item == item_barrell then
    ship.fuel = min(100, ship.fuel + 10)
  end
end

function ship_coll_with_items()
  cbox = abs_box(ship)
  -- some first slices (one more than ship's width)
  for i=1,no_slices do
    items = mapp.items[i]
    -- iterate over slice, check collisions with every block
    for j,v in pairs(items) do
      map_cbox = {
        x1 = (i-1)*8,
        y1 = slice_y_offset + (j-1)*8,
        x2 = i*8-1,
        y2 = slice_y_offset + j*8-1,
      }
      if coll(cbox, map_cbox) then
        ship_apply_item(items[j])
        items[j] = nil
      end
    end
  end
end

function ship_coll_with_map()
  cbox = abs_box(ship)
  -- some first slices (one more than ship's width)
  for i=1,ship.sp_width+1 do
    slice = mapp.slices[i]
    -- iterate over slice, check collisions with every block
    for j=1,#slice do
      if is_solid(slice[j]) then
        map_cbox = {
          x1 = (i-1)*8,
          y1 = slice_y_offset + (j-1)*8,
          x2 = i*8-1,
          y2 = slice_y_offset + j*8-1,
        }
        if coll(cbox, map_cbox) then
          return true
        end
      end
    end
  end
end

function ship_upd()
  local dy = 0
  if btn(2) then dy=-1 end
  if btn(3) then dy=1 end
  -- move and check collision with map
  ship.y = ship.y + dy
  if ship_coll_with_map() then
    ship.y = ship.y - dy
  end
  ship_coll_with_items()

  -- change sprite
  ship.sp = flr(t/15)%2
  if t%10 == 0 then ship.fuel = ship.fuel - 1 end
  if ship.fuel <= 0 then
    goto_game_over("out of %%%")
  end
end

function ship_draw()
  spr(
    ship.sp*ship.sp_width,
    ship.x, ship.y,
    ship.sp_width,
    ship.sp_height
  )
  //b = abs_box(ship)
  //rect(b.x1, b.y1, b.x2, b.y2)
  //print(b.x2, 100, 100)
end
-->8
// map
no_slices = 16
slice_len = 13
slice_y_offset = 16
-- building blocks
block_top_water_flat = 64
block_water = 80
block_grass = 96
block_stone = 112

block_top_water_lower_1 = 70
block_top_water_lower_2 = 86
block_top_water_higher_1 = 71
block_top_water_higher_2 = 87
block_bottom_water_lower = 73
block_bottom_water_higher = 72

item_barrell = 1
-- slice definition
base_slice = {
  block_grass,
  block_grass,
  block_grass,
  block_grass,
  block_grass,
  block_top_water_flat,
  block_water,
  block_water,
  block_grass,
  block_grass,
  block_grass,
  block_grass,
  block_grass
}

function slice_decide(solid_top, solid_bottom)
  local water = slice_len - solid_top - solid_bottom
  local d = {top = 0, bottom = 0}
  -- 0: nothing
  -- 1: higher
  -- 2: lower
  // rand top
  if water > 2 then
    if solid_top > 2 then
      d.top = random_pick({.8,.1,.1})
    else
      d.top = random_pick({.7,.0,.3})
    end
  else
    if solid_top > 2 then
      d.top = random_pick({.7,.3,.0})
    else
      d.top = 0	-- nothing
    end
  end
  // rand bottom
  if water > 2 then
    if solid_bottom > 2 then
      d.bottom = random_pick({.8,.1,.1})
    else
      d.bottom = random_pick({.7,.3,.0})
    end
  else
    if solid_bottom > 2 then
      d.bottom = random_pick({.7,.0,.3})
    else
      d.bottom = 0	-- nothing
    end
  end
  return d
end

-- slice generator
function gen_slice()
  local s = t_clone(mapp.slices[#mapp.slices])
  local no_solid_top = 0
  local no_solid_bottom = 0
  -- count solids from top
  for i=1,#s do
    if s[i] == block_water then
      break
    end
    no_solid_top = no_solid_top + 1
  end
  -- count solids from bottom
  for i=#s,1,-1 do
    if s[i] == block_water then
      break
    end
    no_solid_bottom = no_solid_bottom + 1
  end
  -- decision
  local d = slice_decide(no_solid_top, no_solid_bottom)
  -- apply decision top
  if d.top == 0 then
    if s[no_solid_top] == block_top_water_higher_2 then
      s[no_solid_top] = block_water
      no_solid_top = no_solid_top - 1
    end
    s[no_solid_top] = block_top_water_flat
    if s[no_solid_top-1] == block_top_water_lower_1 then
    end
    // remove that?
    for i=no_solid_top-1,1,-1 do
      s[i] = block_grass
    end
  elseif d.top == 1 then // higher
    if s[no_solid_top] == block_top_water_higher_2 then
      s[no_solid_top] = block_water
      no_solid_top = no_solid_top - 1
    end
    s[no_solid_top-1] = block_top_water_higher_1
    s[no_solid_top] = block_top_water_higher_2
  else -- d.top == 2 // lower
    if s[no_solid_top] != block_top_water_higher_2 then
      s[no_solid_top-1] = block_grass
    else
      no_solid_top = no_solid_top - 1
    end
    s[no_solid_top] = block_top_water_lower_1
    s[no_solid_top+1] = block_top_water_lower_2
  end

  -- apply decision bottom
  local solid_bottom_start = slice_len - no_solid_bottom + 1
  if d.bottom == 0 then
    if s[solid_bottom_start] == block_bottom_water_lower then
      s[solid_bottom_start] = block_water
      solid_bottom_start = solid_bottom_start + 1
    end
    for i=solid_bottom_start,slice_len do
      s[i] = block_grass
    end
  elseif d.bottom == 1 then // higher
    if s[solid_bottom_start] == block_bottom_water_lower then
      s[solid_bottom_start] = block_water
      solid_bottom_start = solid_bottom_start + 1
    end
    s[solid_bottom_start-1] = block_bottom_water_higher
    s[solid_bottom_start] = block_grass
  else -- lower
    if s[solid_bottom_start] == block_bottom_water_lower then
      s[solid_bottom_start] = block_water
      solid_bottom_start = solid_bottom_start + 1
    end
    s[solid_bottom_start] = block_bottom_water_lower
  end
  return s
end

-- map
mapp = {
  draw_offset = 0,
  -- contains one more slice
  slices = {
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice,
    base_slice
  },
  items = {
    {}, {}, {}, {},
    {}, {}, {}, {},
    {}, {}, {}, {},
    {}, {}, {}, {},
    {}
  },
}

function slice_draw(n)
  -- draws i-th slice
  local y = slice_y_offset
  local x = (n-1)*8 - mapp.draw_offset
  local slice = mapp.slices[n]
  local items = mapp.items[n]
  for i=1,slice_len do
    spr(slice[i], x, y)
    if items[i] then
      spr(items[i], x, y)
    end
    y = y+8
  end
end

function new_slice()
  add(mapp.slices, gen_slice())
  del(mapp.slices, mapp.slices[1])
end

function gen_items()
  local ret = {}
  local s = mapp.slices[#mapp.slices]
  
  local water_idx = {}
  for i,b in pairs(s) do
    if b == block_water then
      add(water_idx, i)
    end
  end
  
  local d = random_pick({.93,.07})
  if d == 1 then
    -- find place
    local p = flr(rnd(#water_idx))+1
    ret[water_idx[p]] = item_barrell
  end
  
  return ret
end

function new_items()
  add(mapp.items, gen_items())
  del(mapp.items, mapp.items[1])
end

function map_upd()
  if t%2 == 0 then
    mapp.draw_offset += 2
    if mapp.draw_offset == 8 then
      new_slice()
      new_items()
      mapp.draw_offset=0
    end
  end
end

function map_draw()
  for i=1,no_slices+1 do
    slice_draw(i)
  end
end

-->8
// globals
speed = 30	-- ticks for slice

// utils
function t_clone(t)
  local new_t = {}
  for elem in all(t) do
    add(new_t, elem)
  end
  return new_t
end

function abs_box(obj)
  return {
    x1 = obj.x + obj.box_rel.x,
    y1 = obj.y + obj.box_rel.y,
    x2 = obj.x + obj.box_rel.w + obj.box_rel.x - 1,
    y2 = obj.y + obj.box_rel.h + obj.box_rel.y - 1,
  }
end

function coll(box_a, box_b)
	if box_a.x1 > box_b.x2 or
				box_a.y1 > box_b.y2 or
				box_b.x1 > box_a.x2 or
				box_b.y1 > box_a.y2 then
				return false
	end

	return true
end

function is_solid(spr_no)
  return fget(spr_no, 0)
end

function random_pick(prob)
  local sum = 0
  for x in all(prob) do
    sum = sum + x
  end
  local pick = rnd(sum)
  for i=1,#prob do
    if pick < prob[i] then
      return i - 1
    end
    pick = pick - prob[i]
  end
  return #prob - 1
end
-->8
// background

function background_upd()
end

function background_draw()
  map(0, 0, 0, 0, 16, 2)
end
-->8
// hud

hud_y = 15*8	-- pixels count from 0

function hud_upd()

end

function hud_draw()
  rectfill(0, hud_y, 127, 127, 5)
  -- fuel
  local pos = {x=1, y=hud_y+1}
  local width = 30
  local width2 = ship.fuel/100*width
  local height = 6
  rectfill(
    pos.x, pos.y,
    pos.x+width, pos.y+height-1,
    6
  )
  rectfill(
    pos.x, pos.y,
    pos.x+width2, pos.y+height-1,
    2
  )
end
-->8
// logo
t=0

logoanim=1
logostop=31
logofr=70
function logo_draw()
	local cx = 55
	local cy = 45
	local frx=0//logofr%16*8
	local fry=96//flr(logofr/16)*8
	for s=0,logoanim do
		for x=0,15 do
			camera(rnd(30/t),
				rnd(30/t))
		for y=0,15 do
			if(x+y==s) then
				pset(cx+x,cy+y,12)
			elseif(x+y==s-1) then
				pset(cx+x,cy+y,6) 
			elseif(x+y<s-1) then
				pset(cx+x,cy+y,
					sget(frx+x,fry+y))
			end
		end
	end
end

if(logoanim<=logostop) logoanim+=1
if(t > 35) then
	print("pirrrates",46,cy+20,9)
	print("of the",52,cy+26,8)
	print("river",54,cy+32,12)
 end
end

function logo_upd()
  if btn(4) or btn(5) then
    goto_game()
  end
end

// game over
game_over_reason = ":<"
function game_over_upd()
  if btn(4) or btn(5) then
    goto_logo()
  end
end

function game_over_draw()
  print("game over", 0, 20)
  print(game_over_reason, 0, 40)
end
-->8
//music
__gfx__
00000880000000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000460088000000000000000000460088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466046000000000000000000466046000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466046600000000000000000466046600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466646660000880000000000466646660000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466646666000460000000000466646666000460000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400046666600460000000000400046666600460000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400040000000466000000000400040000000466000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400040000000400000000000400040000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400040000000400000000000400040000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555055555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555500055555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000
44414441414444414440000044414441414444414440000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444440000044444444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44464444444446444600000044446444444444644000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00606644444460666660000000660644444466066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006600000000000000000000006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333300000000000000000000000000000000000000003333333333333333ccccccc33ccccccc000000000000001110000000000000000000000000000000
3333333300000000000000000000000000000000000000003333333333333333cccccc3333cccccc000000000000117771000000000000000000000000000000
9999599900000000000000000000000000000000000000009333333333333339ccccc333333ccccc000000000001776666100000000000000000000000000000
9599999900000000000000000000000000000000000000009933333333333399cccc33333333cccc000000000117666666611000000000000000000000000000
9999999900000000000000000000000000000000000000009993333333333999ccc3333333333ccc000000001776666666666100000000000000000000000000
9999995900000000000000000000000000000000000000009999333333339999cc333333333333cc000000001766666666666610000000000000000000000000
9995999900000000000000000000000000000000000000009999933333399999c33333333333333c000000001766666666666661000000000000000000000000
99999999000000000000000000000000000000000000000099999933339999993333333333333333000000000166666666666661000000000000000000000000
cccccccc0000000000000000000000000000000000000000c99999933999999c0000000000000000000000000016666666666610000000000000000000000000
cccccccc0000000000000000000000000000000000000000cc999999999999cc0000000000000000000000000001111111111100000000000000000000000000
cccccccc0000000000000000000000000000000000000000ccc9999999999ccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000000000000000000000000000cccc99999999cccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000000000000000000000000000ccccc999999ccccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000000000000000000000000000cccccc9999cccccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000000000000000000000000000ccccccc99ccccccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000000000000000000000000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33b333b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc55cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc5555c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c555555c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c556555c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c56c666c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc555555555555cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070007700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070007700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707707707707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707707707707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000001010100000000000000000000000000010000000000000000000100000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
8081808180818081808180818081808100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091909190919091909190919091909100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100006000000000000000000000000000000
011200001c7501f75021050217552175021755210502305024050240552475024755240502605023050230552375023755210501f0551f0502105000000000001c0501f050210502105521050210552105023050
0112000024050240552405024055240502605023050230552305023055210501f055210502105500000000001c0501f0502105021055210502105521050240502605026055260502605526050280502905029055
011200002905029055280502605528050210500000000000210502305024050240552405024055260502605528050210500000000000210502405023050230552305023055240502105023050230550000000000
001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200002405024050230552405024050000002605026050280552605026050000002405024050260552805028050000002805028050260502105021050000002405024050230502105021050000002305023050
011200001f05021050210500000021050230552405024050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002405026050280500000024050260502105000000210502305024050000002605028050290500000021050260502405000000260502305521050210502105000000230501f05028050290502805028050
001000002805028050260500000026050260502405024050230502405024050230502105021050210500000028050290502805028050250502805026050000002605024050230552405024055230502105021050
__music__
00 01424344
00 02424444
00 03424344
00 46424344
00 47424344
00 46424344
00 48424344

