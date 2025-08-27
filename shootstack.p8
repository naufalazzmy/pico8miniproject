pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	screen_w=128-(5*8) --keep left side
	screen_h=128
	cell=8  
	colcount=11
	columns={}
	
	score=0
	numball=0
	
	combo=0
	combo_timer=0
	combo_duration=3
	
	spawn_timer=0
 spawn_interval=1000 -- seconds
	
	shooting=nil
	canshoot=true
	
	pending_power=nil
	
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
	for i=1,3 do
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
  balls[flr(rnd(#balls)+1)],
  balls[flr(rnd(#balls)+1)],
  balls[flr(rnd(#balls)+1)]
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
 
 add(nextballs, balls[flr(rnd(#balls)+1)])
 del(nextballs,nextballs[1])
end

function spawn_all_columns_bottom()
	for i=1,#columns do
   local newstack = {}
   newstack.color = flr(rnd(4)+1) 
   add(columns[i].stacks, newstack, 1)
 end
end

function add_combo()
 combo+=1
 combo_timer=combo_duration*60
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
  
  update_score()
 
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
    
    next_ball()
    
    if shooting.ball.typ!="ball" then
     -- setaip stack ditaruh
     -- ini harus di check dia tipe apa
     -- fungsinya harus baru
    	pending_power = shooting.index
    end
    start_match_process()
    shooting=nil
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
  if btnp(⬇️) and canshoot then
    local col = shooter_col()
    local target_cx = col * cell + (cell/2)
    shooter.x = clamp(target_cx - shooter.w/2, min_x, max_x)
    shoot(col+1,shooter.current)
  end
  
  if btnp(❎) then
   add_power()
  end
  
  update_matches()
end

function update_score()
 if combo_timer>0 then
  combo_timer-=1
   if combo_timer==0 then
    --calculate
    score+=(combo*match_count)
    
    --reset
    combo=0
    match_count=0
   end
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
-- print(combo,2,2,7)
 print("combo: "..combo, 2, 2, 7)
 print("timer: "..flr(combo_timer/30), 2, 10, 7)
 print("#ball: "..match_count, 2, 18, 7)
 print("score: "..(score*100), 2, 26, 7)
-- print("curstack: "..power,2,34,7)
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

function draw_stacks()
 for c=1,#columns do
  if #columns[c].stacks > 0 then
   local bottom = 128 - cell
   for r=1,#columns[c].stacks do
    local stack = columns[c].stacks[r]
    if stack then
     local blink = false
     if match_state == "remove" and pending_matches and pending_matches[c][r] then
      blink = (match_timer % 8) < 4
     end
     if blink then
      spr(0, columns[c].l, bottom)
     else
      spr(stack.color, columns[c].l, bottom)
     end
    end
    bottom -= cell
   end
  end
 end
end
-->8
--match checker
match_state = "idle" -- idle / remove / fall / wait
match_timer = 0
pending_matches = nil
match_count=0

function start_match_process()
 match_state = "check"
end

function find_matches()
 local to_remove = {}

 -- init table tanda
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
    count += 1
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
    count += 1
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

 -- cek square 2x2
 for c=1,#columns-1 do
  for r=1,#columns[c].stacks-1 do
   local a = columns[c].stacks[r]
   local b = columns[c+1].stacks[r]
   local c1 = columns[c].stacks[r+1]
   local d = columns[c+1].stacks[r+1]
   if a and b and c1 and d and
      a.color == b.color and
      a.color == c1.color and
      a.color == d.color then
    to_remove[c][r] = true
    to_remove[c+1][r] = true
    to_remove[c][r+1] = true
    to_remove[c+1][r+1] = true
   end
  end
 end
 
 return to_remove
end

function remove_and_gravity(to_remove)
 add_combo()
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

--checking matches process
function update_matches()
 if match_state == "check" then
	 if pending_power then
	   --todo: can support multiple   
	   pending_matches = power_h(pending_power)
	   pending_power = nil
	   match_state = "remove"
	   match_timer = 15
	   return
	 end
    
  pending_matches = find_matches()
  local found = false
  for c=1,#pending_matches do
   for r=1,#pending_matches[c] do
    if pending_matches[c][r] then
     found = true
     break
    end
   end
   if found then break end
  end
  if found then
   match_state = "remove"
   match_timer = 15 -- wait 15 frames to blink
  else
   match_state = "idle" -- done
  end

 elseif match_state == "remove" then
  match_timer -= 1
  if match_timer <= 0 then
   match_count = count_matches(pending_matches)

   remove_and_gravity(pending_matches)
   match_state = "fall"
   match_timer = 15 -- wait for falling animation
  end

 elseif match_state == "fall" then
  match_timer -= 1
  if match_timer <= 0 then
   match_state = "check" -- check again for combo
  end
 end
end

function count_matches(to_remove)
 local count = 0
 for c=1,#to_remove do
  for r=1,#to_remove[c] do
   if to_remove[c][r] then
    count += 1
   end
  end
 end
 return count
end
-->8
--powerup handler
function add_power()
  local ball={
	  typ="power_h",
	  ismatch=true,
	  sprite=0,
	  color=i,
	  xpos=0,
	  ypos=0
	 }
	 nextballs[1]=ball
end

function power_h(colpos)
  local col = columns[colpos]
  local cur_stack = #col.stacks

  -- siapkan table boolean kayak find_matches
  local to_destroy = {}
  for c=1,#columns do
    to_destroy[c] = {}
    for r=1,#columns[c].stacks do
      to_destroy[c][r] = false
    end
  end

  -- hancurin bola di posisi yg kena efek powerup
  to_destroy[colpos][cur_stack] = true -- bola power sendiri

  -- kanan
  for i=1,2 do
    if columns[colpos+i] and columns[colpos+i].stacks[cur_stack] then
      to_destroy[colpos+i][cur_stack] = true
    end
  end

  -- kiri
  for i=-1,-2,-1 do
    if columns[colpos+i] and columns[colpos+i].stacks[cur_stack] then
      to_destroy[colpos+i][cur_stack] = true
    end
  end
  
  return to_destroy
  
end
__gfx__
0077770000eeee0000cccc0000bbbb0000aaaa000000000000222200000000000000000000000000000000000000000000000000000000000000000000000000
077777700e7777e00c7777c00b7777b00a7777a00000000002eeee20000000000000000000000000000000000000000000000000000000000000000000000000
77666677e766667ec766667cb766667ba766667a000000002e6666e2000000000000000000000000000000000000000000000000000000000000000000000000
77666677e766667ec766667cb766667ba766667a000000002e6886e2000000000000000000000000000000000000000000000000000000000000000000000000
77555577e788887ec7dddd7cb733337ba799997a000000002ed88de2000000000000000000000000000000000000000000000000000000000000000000000000
77555577e788887ec7dddd7cb733337ba799997a000000002edddde2000000000000000000000000000000000000000000000000000000000000000000000000
077777700e7777e00c7777c00b7777b00a7777a00000000002eeee20000000000000000000000000000000000000000000000000000000000000000000000000
0077770000eeee0000cccc0000bbbb0000aaaa000000000000222200000000000000000000000000000000000000000000000000000000000000000000000000
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
