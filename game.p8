pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

t = 0

function _update()
  t = t+1
  background_upd()
  map_upd()
  ship_upd()
  hud_upd()
end

function _draw()
  cls()
  background_draw()
  map_draw()
  ship_draw()
  hud_draw()
end
-->8
// ship
ship = {
  sp_width = 3,
  sp_height = 2,
  x = 10,
  y = 60,
  sp = 0,
  fuel = 100,
  box_rel = {
    x = 0,
    y = 8,
    w = 24,
    h = 8
  }
}

function ship_upd()
  local dy = 0
  if btn(2) then dy=-1 end
  if btn(3) then dy=1 end
  -- move and check collision with map
  ship.y = ship.y + dy
  // todo

  -- change sprite
  ship.sp = flr(t/15)%2
  if t%30 == 0 then ship.fuel = ship.fuel - 1 end
end

function ship_draw()
  spr(
    ship.sp*ship.sp_width,
    ship.x, ship.y,
    ship.sp_width,
    ship.sp_height
  )
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
-- slice definition
base_slice = {
  block_top_water_flat,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_water,
  block_grass
}
-- slice generator
function gen_slice()
  local s = t_clone(base_slice)
  s[3] = block_stone
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
  }
}

function slice_draw(n)
  -- draws i-th slice
  local y = slice_y_offset
  local x = (n-1)*8 - mapp.draw_offset
  local slice = mapp.slices[n]
  for i=1,slice_len do
    spr(slice[i], x, y)
    y = y+8
  end
end

function new_slice()
  add(mapp.slices, gen_slice())
  del(mapp.slices, mapp.slices[1])
end

function map_upd()
  if t%3 == 0 then
    mapp.draw_offset += 1
    if mapp.draw_offset == 8 then
      new_slice()
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
    x2 = obj.x + obj.w + obj.box_rel.x - 1,
    y2 = obj.y + obj.h + obj.box_rel.y - 1,
  }
end

function coll(box_a, box_b)
	local box_a = abs_box(a)
	local box_b = abs_box(b)

	if box_a.x1 > box_b.x2 or
				box_a.y1 > box_b.y2 or
				box_b.x1 > box_a.x2 or
				box_b.y1 > box_a.y2 then
				return false
	end

	return true
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
__gfx__
00000880000000000000000000000000008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000460088000000000000000880000880000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466046000000000000000888888888880808888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466046600000000000008880808808888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466646660000880000008880808888888888008800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000466646666000460000008888088888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400046666600460000000888888880088888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400040000000466000000008888880088808880800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400040000000400000008888888880088880008800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000400040000000400000008800880808888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555508880880800088888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555550080008888800088888808800000000000000000000000000000000000000000000000000000000000000000000000000000000000
44414441414444414440000080008088000800088888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444440000080008888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444000000008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__map__
8081808180818081808180818081808100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091909190919091909190919091909100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100006000000000000000000000000000000
