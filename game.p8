pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

t = 0
state = 0

function goto_game()
		ship.lives = 5
		ship.fuel = 100
		ship.points = 0
		ship.y = 60
		mapp.slices = {
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
  mapp.draw_offset = 0
  mapp.items = {
    {}, {}, {}, {},
    {}, {}, {}, {},
    {}, {}, {}, {},
    {}, {}, {}, {},
    {}
  }

		music(04)
  state = 1
  t = 0
end

function goto_logo()
		music(0, 100)
  state = 0
  logoanim = 1
  t = 0
end

function goto_game_over(r)
  game_over_reason = r
  state = 2
  t = 0
end

function _init()
  goto_logo()
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
  x = 13,
  y = 60,
  sp = 0,
  fuel = 100,
  lives = 5,
  points = 0,
  box_rel = {
    x = 0,
    y = 14,
    w = 20,
    h = 2
  }
}

function ship_apply_item(item)
  if item == item_barrell then
    ship.fuel = min(100, ship.fuel + 10)
  elseif item == item_stone then
    ship.lives = ship.lives - 1
  elseif item == item_boat_1 then
    ship.lives = ship.lives - 1
  elseif item == item_boat_2 then
    ship.lives = ship.lives - 1
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

bullet = nil

function shoot()
  if bullet != nil then return end
  sfx(17)
  bullet = {
    x = ship.x + 20,
    y = ship.y + 12,
    vel_x = 1,
    x_term = 60,
    box_rel = {
      x=0, y=0,
      w=2, h=2
    }
  }
end

function bullet_coll()
  cbox = abs_box(bullet)
  -- some first slices (one more than ship's width)
  for i=1,no_slices do
    items = mapp.items[i]
    -- iterate over slice, check collisions with every block
    for j,v in pairs(items) do
      if v == item_boat_1 or v == item_boat_2 then
       map_cbox = {
         x1 = (i-1)*8,
         y1 = slice_y_offset + (j-1)*8,
         x2 = i*8-1,
         y2 = slice_y_offset + j*8-1,
       }
       if coll(cbox, map_cbox) then
         items[j] = nil
         bullet = nil
         ship.points = ship.points + 1
         return
       end
     end
    end
  end
end


function ship_upd()
  local dy = 0
  if btn(2) then dy=-1 end
  if btn(3) then dy=1 end
  if btn(4) then shoot() end
  -- move and check collision with map
  ship.y = ship.y + dy
  if ship_coll_with_map() then
    ship.y = ship.y - dy
  end
  ship_coll_with_items()

  if bullet != nil then
    bullet.x = bullet.x + bullet.vel_x
    if bullet.x > bullet.x_term then
      bullet = nil
    else
      bullet_coll()
    end
  end

  -- change sprite
  ship.sp = flr(t/15)%2
  if t%10 == 0 then ship.fuel = ship.fuel - 1 end
  if ship.fuel <= 0 then
    goto_game_over("out of %%%")
  elseif ship.lives <= 0 then
    goto_game_over("out of lives :<")
  end
end

function ship_draw()
  spr(
    ship.sp*ship.sp_width,
    ship.x, ship.y,
    ship.sp_width,
    ship.sp_height
  )
  if bullet != nil then
    b = abs_box(bullet)
    rect(b.x1, b.y1, b.x2, b.y2, 5)
  end  
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

block_top_water_lower_1 = 70
block_top_water_lower_2 = 86
block_top_water_higher_1 = 71
block_top_water_higher_2 = 87
block_bottom_water_lower = 73
block_bottom_water_higher = 72

item_barrell = 113
item_stone = 112
item_boat_1 = 6
item_boat_2 = 7
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
  local itms = mapp.items[#mapp.items]

  local water_idx = {}
  for i,b in pairs(s) do
    if itms[i] == item_boat_1 then
      ret[i] = item_boat_2
    elseif b == block_water then
      add(water_idx, i)
    end
    
  end

  -- barrell
  local d = random_pick({.93,.07})
  if d == 1 and #water_idx>1 then
    -- find place
    local p = flr(rnd(#water_idx))+1
    ret[water_idx[p]] = item_barrell
    del(water_idx, p)
  end

  -- stone
  d = random_pick({.98,.02})
  if d == 1 and #water_idx>1 then
    local p = flr(rnd(#water_idx))+1
    ret[water_idx[p]] = item_stone
    del(water_idx, p)
  end

  -- boat
  d = random_pick({.95,.05})
  if d == 1 and #water_idx > 1 then
    local p = flr(rnd(#water_idx))+1
    ret[water_idx[p]] = item_boat_1
    del(water_idx, p)
  end

  return ret
end

function new_items()
  add(mapp.items, gen_items())
  del(mapp.items, mapp.items[1])
end

function check_hard_coll()
  local i=5
  local slice = mapp.slices[i]
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

function map_upd()
  if t%2 == 0 then
    mapp.draw_offset += 2
    if mapp.draw_offset == 8 then
      new_slice()
      new_items()
      mapp.draw_offset=0
      if check_hard_coll() then
        goto_game_over("crashed")
      end
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
cloud_x=128
cloud_x2=100
cloud_x3=55


function background_upd()
		cloud_x=cloud_x-1
		if cloud_x<-16 then
		  cloud_x=128
		end
		
		cloud_x2=cloud_x2-1.25
		if cloud_x2<-16 then
		  cloud_x2=128
		end
		
		cloud_x3=cloud_x3-1.5
		if cloud_x3<-16 then
		  cloud_x3=128
		end
end

function background_draw()
  map(0, 0, 0, 0, 16, 2)
  spr(075,cloud_x,0,2,2)
  spr(075,cloud_x2,1,2,2)
  spr(075,cloud_x3,2,2,2)
  spr(067,0,5,2,2)
  spr(067,5,5,2,2)
  spr(067,20,5,2,2)
  spr(067,25,5,2,2)
  spr(067,40,5,2,2)
  spr(067,55,5,2,2)
  spr(067,60,5,2,2)
  spr(067,75,5,2,2)
  spr(067,90,5,2,2)
  spr(067,105,5,2,2)
  spr(067,120,5,2,2)
end


-->8
// hud

hud_y = 15*8	-- pixels count from 0

function hud_upd()

end

function hud_draw()
  rectfill(0, hud_y, 127, 127, 5)
  -- fuel
  local pos = {x=13, y=hud_y+1}
  local width = 30
  local width2 = ship.fuel/100*width
  local height = 6
  print("%%%", 1, hud_y+1, 2)
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
  print(ship.points, 55, hud_y+1)
  
  --draw the hearts
  for i=1,ship.lives do
  	spr(077,80+i*8,hud_y)
  end
  
  for i=5,ship.lives+1,-1 do
  	spr(078,80+i*8,hud_y)
  end
end
-->8
// logo
logoanim=1
logostop=61
logofr=70
function logo_draw()
	local cx = 55
	local cy = 45
	local frx=0//logofr%16*8
	local fry=96//flr(logofr/16)*8
	for s=0,logoanim do
		for x=0,15 do
			camera(rnd(60/t),
				rnd(60/t))
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
 if(t > 70) then
 	print("pirrrates",46,cy+20,9)
 	print("of the",52,cy+26,8)
 	print("river",54,cy+32,12)
 end
 if t>80 then
   local vis = flr((t-80)/10)%2
   if vis == 1 then
     print("press fire", 44, cy+40, 4)
   end
 end

end


function logo_upd()
  if t>logostop then
  if btn(4) or btn(5) then
    goto_game()
  end
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
  print("points: "..ship.points, 0, 70)
end
-->8
//music
__gfx__
00000880000000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000460088000000000000000000460088000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000
00000466046000000000000000000466046000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000
00000466046600000000000000000466046600000000000044444445444444440000000000000000000000000000000000000000000000000000000000000000
00000466646660000880000000000466646660000880000004444444544444440000000000000000000000000000000000000000000000000000000000000000
00000466646666000460000000000466646666000460000004444444455444400000000000000000000000000000000000000000000000000000000000000000
00000400046666600460000000000400046666600460000000044444455540000000000000000000000000000000000000000000000000000000000000000000
00000400040000000466000000000400040000000466000000000000005550000000000000000000000000000000000000000000000000000000000000000000
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
3333333300000000000000000000005500000000000000003333333333333333ccccccc33ccccccc000000000000001110000000000000000000000000000000
3333333300000000000000000000055550000000000000003333333333333333cccccc3333cccccc000000000000117771000000088088000660660000000000
9999599900000000000000000000555555000000000000009333333333333339ccccc333333ccccc000000000001776666100000888888806666666000000000
9599999900000000000000000005555555000000000000009933333333333399cccc33333333cccc000000000117666666611000888888806666666000000000
9999999900000000000000000005555555550000000000009993333333333999ccc3333333333ccc000000001776666666666100088888000666660000000000
9999995900000000000000000055555555555000000000009999333333339999cc333333333333cc000000001766666666666610008880000066600000000000
9995999900000000000000000555555555555500000000009999933333399999c33333333333333c000000001766666666666661000800000006000000000000
99999999000000000000000055555555555555500000000099999933339999993333333333333333000000000166666666666661000000000000000000000000
cccccccc0000000000000000555555555555555000000000c99999933999999c0000000000000000000000000011111111111110000000000000000000000000
cccccccc0000000000000000555555555555555500000000cc999999999999cc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000555555555555555500000000ccc9999999999ccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000555555555555555500000000cccc99999999cccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000555555555555555500000000ccccc999999ccccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000555555555555555500000000cccccc9999cccccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000555555555555555500000000ccccccc99ccccccc0000000000000000000000000000000000000000000000000000000000000000
cccccccc0000000000000000555555555555555500000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33b333b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc55cccc4424cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc5555cc542445c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c555555c544244450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c556555c544244450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c56c666cc546445c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6cccccccc6c66cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100006000000000000000000000000000000
011200001c7501f75021050217552175021755210502305024050240552475024755240502605023050230552375023755210501f0551f0502105000000000001c0501f050210502105521050210552105023050
0112000024050240552405024055240502605023050230552305023055210501f055210502105500000000001c0501f0502105021055210502105521050240502605026055260502605526050280502905029055
011200002905029055280502605528050210500000000000210502305024050240552405024055260502605528050210500000000000210502405023050230552305023055240502105023050230550000000000
001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200002405024050230552405024050000002605026050280552605026050000002405024050260552805028050000002805028050260502105021050000002405024050230502105021050000002305023050
011200001f05021050210500000021050230552405024050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002405026050280500000024050260502105000000210502305024050000002605028050290500000021050260502405000000260502305521050210502105000000230501f05028050290502805028050
001000000f4750f3650f4550f2750f3550f4650f2750f3650f4550f3750f3550f4650f2750f3550f4750f2550c25500475003550c4650c275003650c3750c25500465003750c4751025504365044751025510365
001000001647516355164751625516365164751626516355164751635516365164751625516365164751625513255134651f375134551f26513375133651f2751335516465134751626513355164751327516355
0010000013363132651f455074752b6652b453133751f45513263134751f455074652b67513443133651347513353042651f475044552b66504473133552846513373042552b465074752b655134630437504455
001000001d4601d46211462114621d4661f4621d46222462244621d462294621f4621f46229462274621d4621d4621d4622446124462244622446024462274602946229462274672d4622e461294652746229362
001000001f0721f1721f0721f1761f276203761f2761d2761f076211761f0761d1761f276223761f2761b2762b07726177240771f1772627726377242771f2771a077181771f0771a177182771f3771a2771f277
001000002947529372295722927529372294722927529475294752937229572292752937229472292752947528471283752857528275283752847528272284752847528372285752827528371284762827528472
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01424344
00 02424444
00 03424344
00 46424344
00 08094344
01 08094344
01 08090a44
01 08090a44
01 0b090a44
01 0b090a44
01 0c090a44
01 090a0b44
01 0d090a44
01 0d090a44
01 090a0c44
01 090a0c44

