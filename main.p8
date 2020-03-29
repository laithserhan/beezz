pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- beeeeeees
-- by us

-- ** technical ** --
function abs_box(o)
-- absolute box for object o
 local box = {}
 box.x1 = o.box.x1 + o.x
 box.y1 = o.box.y1 + o.y
 box.x2 = o.box.x2 + o.x
 box.y2 = o.box.y2 + o.y
 return box
end

function iou(o1,o2)
-- intersection over union of two objects
-- return percentage in [0,1], 1 is perfect match
 local box_o1 = abs_box(o1)
 local box_o2 = abs_box(o2)
 
 -- x,y coordinates of intersection
 local x1 = max(box_o1.x1,box_o2.x1)
 local y1 = max(box_o1.y1,box_o2.y1)
 local x2 = min(box_o1.x2,box_o2.x2)
 local y2 = min(box_o1.y2,box_o2.y2)
 
 -- area of intersection
 local inter_area = max(0, x2 - x1 + 1) * max(0, y2 - y1 + 1)
 
 -- area of both boxes
 local o1_area = (box_o1.x2 - box_o1.x1 + 1) * (box_o1.y2 - box_o1.y1 + 1)
 local o2_area = (box_o2.x2 - box_o2.x1 + 1) * (box_o2.y2 - box_o2.y1 + 1)

 return inter_area / (o1_area + o2_area - inter_area)
end

function debug_infos(x,y)
 camera() -- reset camera before drawing

 if(btn(0)) then print("⬅️",x,y+6,7) end
 if(btn(1)) then print("➡️",x+16,y+6,7) end
 if(btn(2)) then print("⬆️",x+8,y,7) end
 if(btn(3)) then print("⬇️",x+8,y+6,7) end
 if(btn(4)) then print("🅾️",x+16,y,7) end
 if(btn(5)) then print("❎",x,y,7) end
 print("tmr:"..p.tmr,x,y+16,7)
 print("p.x:"..p.x,x,y+24,7)
 print("p.y:"..p.y,x,y+32,7)
end

-- ** bee - general ** --
function bee_base_init()
 p={
  name="barry",
  tot_pln=0,  -- cumulative polen
  cur_pln=0,  -- current polen
  max_pln=10,  -- max usable polen before slowdown in speed
  cur_spd=3,  -- speed
  max_spd=3,
  x=64,  -- x,y coordinate, RELATIVE TO THE SCREEN
  y=64,
  box={x1=1,y1=1,x2=14,y2=14},  -- collision box
  sp=0,  -- current sprite
  sp_st=0,  -- first sprite of the animation
  sp_sz=2,  -- sprite size
  flp_x=false,  -- should the sprite be flipped horizontally
  flp_y=false,  -- should the sprite be flipped vertically
  action=false,  -- can't move if action is true
  tmr=0  -- internal timer
 }
end

function bee_draw()
 spr(p.sp,p.x,p.y,p.sp_sz,p.sp_sz,p.flp_x,p.flp_y)
end

-- ** actual game ** --
function _init()
 menu_init()
end
-->8
-- menu and intro
function menu_init()
 _update=menu_update
 _draw=menu_draw
end

function menu_update()
 if(btnp(5)) then
  intro()
 end
end

function menu_draw()
 cls()
 spr(10,54,54,2,2)
 print("press ❎ to start",30,63)
end

function intro()
 -- todo lol
 bee_base_init()
 exploration_init()
 _update=exploration_update
 _draw=exploration_draw
end
-->8
-- exploration
-- ** exploration - initialisation ** --
function flowers_init(nbr)
-- create a number of flowers between 1 and nbr.
 flowers={}
 
 for i=1,nbr do
  add(flowers,{
   x=flr(rnd(map_width-32)+16),  -- x,y coordinates
   y=flr(rnd(map_height-32)+10),
   box={x1=2,y1=3,x2=29,y2=29},  -- collision box
   sp=42,  -- current sprite
   sp_bs_clr=13,  -- base color, used to change the color
   sp_clr=flr(rnd(4)+13),  -- final color
   sp_sz=4,  -- sprite size
   pln=flr(rnd(6))  -- polen quantity
  })
 end
end

function hive_init()
-- put the ruche in a random place
-- yes i know it's hive in english gimme a break
 hive={
  x=flr(rnd(map_width/3)+map_width/3),  -- x,y coordinates
  y=flr(rnd(map_height/3)+map_height/3),
  box={x1=10,y1=14,x2=18,y2=22},  -- collision box, centered on the door
  sp=70,  -- current sprite
  sp_sz=4,  -- sprite size
  pln=0  -- polen quantity
  }
end

function exploration_init()
 -- map
 map_width=128*3
 map_height=128*3
 
 -- flowers
 flowers_init(15)
 
 -- hive
 hive_init()
 
 -- camera coordinates for the map
 cam_x=0
 cam_y=0
 
 tlrnc=0.10  -- percentage of match between bee and flower
end

-- ** exploration - updating ** --
function bee_update()
 p.tmr+=1  -- internal timer. 30fps
 
 if(not p.action) then
  -- animation
  if(p.tmr == 10) then
   p.sp = p.sp_st
  end
  if(p.tmr >= 20) then
   p.sp += p.sp_sz
   p.tmr = 0  -- restart timer
  end
  
  -- actions
  -- left
  if(btn(0)) then
   p.sp_st=32
   p.flp_x=true
   
   if(cam_x > 0 and p.x-cam_x==64) then
    cam_x-=p.cur_spd
    p.x-=p.cur_spd
   else
    if(p.x > 4) then
     p.x-=p.cur_spd
    end
   end
  end
  
  -- right
  if(btn(1)) then
   p.sp_st=32
   p.flp_x=false
   
   if(cam_x < map_width-128 and p.x-cam_x==64) then
    cam_x+=p.cur_spd
    p.x+=p.cur_spd
   else
    if(p.x < map_width-4 - p.sp_sz * 8) then
     p.x+=p.cur_spd
    end
   end
  end
  
  -- up
  if(btn(2)) then
   p.sp_st=0
   p.flp_y=false
   
   if(cam_y > 0 and p.y-cam_y==64) then
    cam_y-=p.cur_spd
    p.y-=p.cur_spd
   else
    if(p.y > 4) then
     p.y-=p.cur_spd
    end
   end
  end
  
  -- down
  if(btn(3)) then
   p.sp_st=0
   p.flp_y=true
   
   if(cam_y < map_height-128 and p.y-cam_y==64) then
    cam_y+=p.cur_spd
    p.y+=p.cur_spd
   else
    if(p.y < map_height-4 - p.sp_sz * 8) then
     p.y+=p.cur_spd
    end
   end
  end
  
  -- action (X) -- todo talk w/ bees
  if btn(5) then
   p.action=true  -- lock the player
   p.tmr = 0  -- restart timer
  end
 else
  get_down()
  -- get_pln()
  -- get_into_hive()
 end
 
 -- polen
  p.cur_spd=p.max_spd-flr(p.cur_pln/(p.max_pln + 1))
end

function get_down()
-- basically an animation with black magic...
 if(p.tmr == 15) then
  p.sp = p.sp_st + 2 * p.sp_sz
 end
 if(p.tmr == 30) then
  p.sp += p.sp_sz
 end
 if(p.tmr == 45) then
  p.sp += p.sp_sz
 end
 if(p.tmr == 75) then
  -- first try to get into hive
  get_into_hive()
  
  -- if not into hive, try to collect polen
  for f in all(flowers) do
   if(check_flower(f)) then
    -- todo break, idk how to do that
   end
  end
  foreach(flowers,check_flower)
 end
 if(p.tmr == 120) then
  p.sp -= p.sp_sz
 end
 if(p.tmr == 135) then
  p.sp -= p.sp_sz
 end
 if(p.tmr == 150) then
  p.sp -= p.sp_sz
  p.action=false
 end
end

function get_into_hive()
 if(iou(p,hive) >= tlrnc) then
  story_init()
  return true
 else
  return false
 end
end

function check_flower(f)
 if(iou(p,f) >= tlrnc) then
  p.cur_pln+=f.pln
  f.pln = 0
  return true
 else
  return false
 end
end

function get_pln()
-- basically an animation with black magic...
end

function exploration_update()
 bee_update()
end

-- ** exploration - drawing ** --
function hive_draw()
 spr(hive.sp,hive.x,hive.y,hive.sp_sz,hive.sp_sz)
end

function flower_draw(f)
 -- general flower color
 pal(f.sp_bs_clr,f.sp_clr)
 
 -- if the flower is empty, the pistil is not shown
 if(f.pln == 0) then
  pal(9,1)
 end
 -- the actual flower
 spr(f.sp,f.x,f.y,f.sp_sz,f.sp_sz)
 pal() 
 if(f.pln > 0) then
  for i=1,f.pln do
   -- beautiful polen bits...
   pset(f.x+4*f.sp_sz+i*.8,f.y+4*f.sp_sz+i*.7,9)
   pset(1+f.x+4*f.sp_sz+i*.8,f.y+4*f.sp_sz+i*.7,9)
   pset(f.x+4*f.sp_sz+i*.8,1+f.y+4*f.sp_sz+i*.7,9)
   pset(1+f.x+4*f.sp_sz+i*.8,1+f.y+4*f.sp_sz+i*.7,9)
  end
 end
end

function exploration_draw()
 -- first reset the fucker
 cls()
 
 -- set the camera to the current location
 camera(cam_x, cam_y)
 
 -- draw the entire map -- todo
 map(0, 0, 0, 0, 128, 64)
 
 -- hive
 hive_draw()
 
 -- flowers
 foreach(flowers,flower_draw)
 
 -- bee
 bee_draw() 
end
-->8
-- story
function story_init()

end

function story_update()

end

function story_draw()

end
__gfx__
000000000000000000000099900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d222222d
0000009990000000000009191900000000000000000000000000000000000000000000000000000000000677067000000000000000000000000000001d2222d6
0000091919000000000002222200000000000019100000000000000000000000000000000000000000000d677677000000000670077000000000000011dddd66
00000222220000000007776d6777000000000022200000000000001910000000000000000000000000000d66776700000000d677677700000000000011dddd66
0000776d67700000007776d2d67770000000006d600000000000007d700000000000001910000000000000d6776700000000d677767700000000000011dddd66
000776d2d677000007766d999d677700000076d2d6700000000007d2d700000000000072700000000000222d6767000000000d67767700000000000011dddd66
007776d9d67770000766d22222d6670000076d999d67000000007d999d700000000007696700000000022929d6260000000022d6766700000000000011dddd66
00776d222d67700006dd9999999dd6000066d22222d660000000d22222d000000000062226000000001929292d2999000002292d672600000000000011dddd66
0076d99999d670000000222222200000000009999900000000000099900000000000009990000000111929292929919000192929d6299900d666666711dddd66
006dd22222dd600000009999999000000000022222000000000000222000000000000001000000000019292929299990111929292d2991902d66667611dddd66
000099999990000000002222222000000000099999000000000000010000000000000000000000000002292929299900001929292929999022dddd6611dddd66
000022222220000000000999990000000000002220000000000000000000000000000000000000000000292922000000000229292929990022dddd6611dddd66
000009999900000000000011100000000000000100000000000000000000000000000000000000000000000000000000000029292200000022dddd6611dddd66
000000111000000000000001000000000000000100000000000000000000000000000000000000000000000000000000000000000000000022dddd6611dddd66
0000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221111d61d666676
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002111111dd6666667
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000067700000000000000000000000000000000000000000000000000000000000777777700000007777777000000000000000000000
000000677700000000000000d6770000000000006000000000000000000000000000000000000000000007776777610000667777777700000000000000000000
000000d67770000000000000d6677000000000006700000000000000000000000000000000000000000007776677611000677776677700000000000000000000
000029dd67770000000002929d67700000000000d670000000000000d700000000000000000000000000077771177d10011676d1177600000000000000000000
00092929d66729000000929292d67290000009292d600000000000002d70000000000000670000000000066677d11d111116dd17776600000000000000000000
001929292dd6219000019292929d62190000292929d621000000002929d710000000000926710000000001dd677d1d222211d117776600000000000000000000
11192929292d2990011192929292d29900112929292d290000000129292d900000000019292900000000011dd66d127777221167766600000000000000000000
001929292dd6219000019292929d62190000292929d621000000002929d71000000000092671000000000011dddd279999721d66661000000000000000000000
00092929d66729000000929292d67290000009292d600000000000002d7000000000000067000000000000011dd2299999922dddd11000000000000000000000
000029dd67770000000002929d67700000000000d670000000000000d70000000000000000000000000000661112999999992ddd110000000000000000000000
000000d67770000000000000d67770000000000067000000000000000000000000000000000000000000777666d2999999992111166777000000000000000000
000000677700000000000000d67700000000000060000000000000000000000000000000000000007777776666d2299999922dd6666777770000000000000000
000000000000000000000000677000000000000000000000000000000000000000000000000000007777776ddddd22999922ddddd66667770000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000666711111111292222921111111116770000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000011666666dddd22999922dddd666666710000000000000000
97111111111111191111111997111111333333333333333300000000000000000000000000000000011d66666ddd12222221ddd6666666110000000000000000
971111111111111911111119971111113313d3333dd3dd33000000000000000000000000000000000011dddddddd11222211ddddddddd1100000000000000000
971111111111111911111119971111113333333333313d3300000000000000000000000000000000000111dd11111111111111111dd111000000000000000000
97111111111111191111111997711111333337333331333100000000000000099999999999900000000001111dddd1dd1dd1dddd111100000000000000000000
971111111111111911111199999771113d337973333333330000000999999999999aaa999999900000000066677d1ddd1ddd1776610000000000000000000000
97111111111111191111999999999771313dd73333333d3100000099999999aaa99aaa9999999000000006666761666d1d666177666000000000000000000000
9977711111111199111999911999999733333333133333330000099aaa9999aaa999aa999999900000000666761776dd1d677617766700000000000000000000
1999771111119991199991111119999933333333333333330000999aaa99999999999aa99999990000000767717776d111667761777700000000000000000000
1199997111199911999111111111199933133dd3333333330000999aa999999999999aa999aa990000000777767766d101167776677700000000000000000000
111199977999111197111111111111193d133333333d33330000999aa999999999999aa999aa99000000077777776d1100666777777700000000000000000000
1111119999911111971111111111111933333333333733330000999aa99999aaa999999999999900000007777776611000666677777700000000000000000000
1111111999111111971111111111111933333333337973330000999aa9999aaaa99999999aa99900000000777776100000006677777700000000000000000000
11111119971111119711111111111119311331d3333733d30009999aaaa99aa99999999aaaa99900000000000000000000000000000000000000000000000000
11111119971111119711111111111119333333333333333300099999aaa9999999999aaaaaa99900000000000000000000000000000000000000000000000000
111111199711111197111111111111193d333333333d313300099999aa99999999999aaaa9999000000000000000000000000000000000000000000000000000
11111119971111119711111111111119333331333333333300099999aaa999999999999999990000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000999aa9aaa99999999999999990000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000999aa9aaa995599aaaaaa99900000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000999aa99aa955559aaaaaaa9000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000099999999995555999999aa9000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000009aa99999995555999999999000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000009aa9999aa9999aaa999999aa00000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000009aa9999aa9999aaaaaaa99aa00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000099aaa99aa999999aaaaa99aa00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000099aaaa9aa999aaa99999999000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000999aaa999999aaaaa999999000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000999999999999aaaaaaa999000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000009999999aa999999aaaaa90000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000009999999aaaa9999999aa00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000999999aaa9999aaa9000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000009999999aaa99aaa0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000099999aaa900000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454445400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555455500000000000000000000000000000000
__map__
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454041404140414041404140414041404140414041404140414041404140414041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555051505150515051505150515051505150515051505150515051505150515051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454243424342434243424342434243424342434243424342434243424342434243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555253525352535253525352535253525352535253525352535253525352535253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454041404140414041404140414041404140414041404140414041404140414041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555051505150515051505150515051505150515051505150515051505150515051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454243424342434243424342434243424342434243424342434243424342434243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555253525352535253525352535253525352535253525352535253525352535253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454041404140414041404140414041404140414041404140414041404140414041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555051505150515051505150515051505150515051505150515051505150515051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454243424342434243424342434243424342434243424342434243424342434243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555253525352535253525352535253525352535253525352535253525352535253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454041404140414041404140414041404140414041404140414041404140414041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555051505150515051505150515051505150515051505150515051505150515051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544454243424342434243424342434243424342434243424342434243424342434243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554555253525352535253525352535253525352535253525352535253525352535253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554444544455554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544545554554544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554444544455554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544545554554544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554552f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445444544454445444544454445444544454445444544454445444544454445444544454445444544454445444544452f2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455545554555455545554555455545554555455545554555455545554555455545554555455545554555455545554550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
