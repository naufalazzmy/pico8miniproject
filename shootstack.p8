pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	screen_w=128-(5*8) --keep left side
	screen_h=128
	cell=8  
	colcount=11
	columns={}
	
	combo=0
	score=0
	
	spawn_timer=0
 spawn_interval=1000 -- seconds
	
	shooting=nil
	canshoot=true
	
	--columns grid map
	for i=1,colcount do
  local col={}
  col.index=i-1
  col.l=(i - 1) * cell
  col.r=col.l + cell
  col.stacks={}
  add(columns, col)
	end
	
	--player
	shooter = {
	  x=screen_w/2,
	  y=0,  
	  w=8,            
	  h=8,             
	  speed=120,      
	  color=7,
	  current=nil          
	}
	
	--generate ball prop
	balls={}
	for i=1,4 do
	 local ball={
	  typ="ball",
	  ismatch=true,
	  sprite=i,
	  color=i,
	  xpos=0,
	  ypos=0
	 }
	 add(balls,ball)
	end
	
 --generate balls
 nextballs={
  balls[flr(rnd(4)+1)]
 }
 
 next_ball()
 
end
-->8
--helper
function clamp(v, a, b) 
 if v<a then 
  return a
 end 
 if v>b then 
  return b 
 end 
 
 return v 
end

function max_height()
 return screen_h/8-1
end
--get current shooter loc
function shooter_col()
  local cx = shooter.x + shooter.w/2
  cx = clamp(cx, 0, screen_w-1)
  local col = flr(cx / cell)
  
  return col
end

function next_ball()
 shooter.current=nextballs[1]
 shooter.current.ypos=shooter.y
 shooter.current.xpos=shooter.x
 
 del(nextballs,nextballs[1])
 add(nextballs, balls[flr(rnd(4)+1)])
end

function spawn_all_columns_bottom()
	for i=1,#columns do
   local newstack = {}
   newstack.color = flr(rnd(4)+1) 
   add(columns[i].stacks, newstack, 1)
 end
end

function shoot(index,ball)
 local targetpos=128-(cell*#columns[index].stacks)-cell
 local spd=1
 
	shooting = {
  ball=ball,
  index=index,
  xpos=shooter.x,
  ypos=shooter.y,
  targetpos=targetpos,
  spd=12
 }
end


-->8
--update
function _update60()
  local dt = 1/60
  spawn_timer+=1/60
  
  if spawn_timer >= spawn_interval then
   spawn_timer = 0
   spawn_all_columns_bottom()
  end

  local vx = 0
  if btn(⬅️) then 
   vx = vx - 1
  end
  if btn(➡️) then 
   vx = vx + 1 
  end
  if shooting then
   canshoot=false
   shooting.ypos += shooting.spd
   if shooting.ypos >= shooting.targetpos then
    add(columns[shooting.index].stacks, shooting.ball)
    shooting=nil
    next_ball()
    canshoot=true
   end
  end

  -- shooter move
  shooter.x = shooter.x + vx * shooter.speed * dt

  -- batas layar
  local min_x = 0
  local max_x = screen_w - shooter.w
  shooter.x = clamp(shooter.x, min_x, max_x)

  -- snap ke grid & shoot
  if btnp(❎) and canshoot then
    local col = shooter_col()
    local target_cx = col * cell + (cell/2)
    shooter.x = clamp(target_cx - shooter.w/2, min_x, max_x)
    shoot(col+1,shooter.current)
  end
  
  if btnp(🅾️) then
   process_matches()
  end
  
  
end
-->8
--draw
function _draw()
 cls(1)
 --draw_grid()
 draw_shotline()
 draw_shooter()
 draw_stacks()
 draw_nextball()
 debug_col()
end

function debug_col()
 --local col=shooter_col()
 print(combo,2,2,7)
-- print(shooter.current.ypos,56,56)
 --print(columns[1].stacks[1].color,7)
end

function draw_nextball()
 local start=93
 print("next",start,0,7)
 for ball in all(nextballs) do
  spr(ball.sprite,start,8)
  start+=11
 end
end

function draw_grid()
 for col in all(columns) do
  rect(col.l, 0, col.r - 1, screen_h - 1, 13)
 end
end

function draw_shotline()
 for col in all(columns) do
  local current=shooter_col()
  if col.index==current do
   rectfill(col.l,0,col.r - 1,128,13)
  end
 end
end

function draw_shooter()
 local sx = flr(shooter.x)
 local sy = flr(shooter.y)
 
	if shooting then
  spr(shooting.ball.sprite, shooting.xpos, shooting.ypos)
 else
  spr(shooter.current.sprite,sx,sy)
 end
 spr(16,sx,sy)
end

--draw balls in stack
function draw_stacks()
 for col in all(columns) do
  if #col.stacks>0 then
	  local bottom=128-cell
	  
	  for ball in all(col.stacks) do
	   if ball~=nil then
     spr(ball.sprite,col.l,bottom)
	    bottom-=cell
	   end
	  end
	  
	 end
 end
end
-->8
--match checker
function find_matches()
 local to_remove = {}

 -- buat table kosong untuk tanda
	for c=1,#columns do
	 to_remove[c] = {}
	 for r=1,#columns[c].stacks do
	  to_remove[c][r] = false
	 end
 end

 -- cek horizontal
 for r=1,max_height() do
  local count = 1
  for c=2,#columns+1 do
   local prev = columns[c-1].stacks[r]
   local curr = columns[c] and columns[c].stacks[r] or nil
  
   if curr and prev and curr.color == prev.color then
    count = count + 1
   else
    if count >= 3 then
    
     for k=c-count, c-1 do
      to_remove[k][r] = true
     end
     
    end
    count = 1
   end
  end
 end

 -- cek vertical
 for c=1,#columns do
  local count = 1
  for r=2,#columns[c].stacks+1 do
   local prev = columns[c].stacks[r-1]
   local curr = columns[c].stacks[r]
   if curr and prev and curr.color == prev.color then
    count = count + 1
   else
	   if count >= 3 then
	    for k=r-count, r-1 do
	     to_remove[c][k] = true
	    end
	   end
   count = 1
   end
  end
 end

 return to_remove
end

function remove_and_gravity(to_remove)
 combo+=1
 for c=1,#columns do
  local newstack = {}
  for r=1,#columns[c].stacks do
   if not to_remove[c][r] then
    add(newstack, columns[c].stacks[r])
   end
  end
  columns[c].stacks = newstack
  end
end

-- init this to precess
function process_matches()
 while true do
  local matches = find_matches()
  local has_match = false
  for c=1,#matches do
   for r=1,#matches[c] do
    if matches[c][r] then
     has_match = true
     break
    end
   end
   if has_match then break end
   end
   if not has_match then break end
    remove_and_gravity(matches)
  end
end
__gfx__
0077770000eeee0000cccc0000bbbb0000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777700e7777e00c7777c00b7777b00a7777a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666677e766667ec766667cb766667ba766667a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666677e766667ec766667cb766667ba766667a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77555577e788887ec7dddd7cb733337ba799997a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77555577e788887ec7dddd7cb733337ba799997a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777700e7777e00c7777c00b7777b00a7777a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077770000eeee0000cccc0000bbbb0000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e7777e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e766667e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e766667e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e755557e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e755557e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e7777e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
