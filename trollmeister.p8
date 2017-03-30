pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
------ trollmeister ------
----- made by fabian -----

corrupt_mode=false

--game state enums
c_menu_state=0
c_game_state=1
c_lose_state=2
c_win_state=3
c_freeze_state=4
c_boss_dead_state=5

--direction constants
c_left=-1
c_right=1

--player sprites
c_player_sprs={
 walk={001,002,001,003},
 jump=017,
 fall=018
}
c_life_spr=016
c_dead_player_sprs={
 jump=033,
 fall=034
}
c_happy_player_sprs={049}

--enemy sprites
c_stomper_sprs={
 walk={010,010,011,011,
       010,010,012,012}
}
c_ghost_sprs={
 walk={026,027,028,029,030,
       031,030,029,028,027}
}
c_frog_sprs={
 walk={042},
 jump=043,
 fall=044
}
c_boss_sprs={
 walk={006,007,006,008},
 jump=022,
 fall=023,
 up=024
}
c_shot_left_sprs={
 walk={055}
}
c_shot_up_sprs={
 walk={056}
}

--level colors
c_lvl_clrs={
 {9,4},
 {12,1},
 {8,2},
 {14,2},
 {7,6},
 {9,1},
 {15,13},
 {3,2}
} 

--used for animation
c_walk_count_max=20

--physics constants
c_jump_vel=-1.8
c_bounce_vel=-1.2
c_gravity=0.1
c_gravity_max=2.0

c_walk_acc=0.1
c_walk_ret=0.4
c_walk_ret_air=0.025
c_walk_ret_wall=0.8
c_walk_max=1.0

c_stomper_dx=0.8
c_stomper_ddx=0

c_ghost_ddy=0.2
c_ghost_dy_max=2

c_frog_jump_dx=1.0
c_frog_jump_dy=-1.5
c_frog_ddy=0.2
c_frog_jump_dy_max=2.0

--sprite tile width/height
c_tile_side=8
--map width/height
c_map_side=16
--y coordinate for the
-- copied map
c_copy_map_y=c_map_side*3

--sprite flags
c_solid_flag=0
c_pl1_flag=1
--c_pl2_flag=2
c_life_flag=2
c_goal_flag=3
c_stomper_flag=4
c_ghost_flag=5
c_spike_flag=6
c_frog_flag=7

--enemy types
c_stomper=0
c_ghost=1
c_frog=2
c_boss=3
c_shot=4

--used for button input
c_pl1_no=0
c_pl2_no=1

--music tracks
c_menu_music=00
c_lvl1_music=05
c_lose_music=07
c_boss_music=12
c_boss_dead_music=10
c_win_music=20

--sound effects
c_jump_sfx=0
c_die_sfx=11
c_debug_sfx=12
c_goal_sfx=13
c_walk_sfx=14
c_kill_sfx=15
c_frog_sfx=22
c_shot_sfx=23
c_warp_sfx=27
c_boss_sfx=26
c_life_sfx=28

c_start_lvl=0
c_n_lives=3

function lvl_x()
 return lvl_map*c_map_side
end

function 
has_flag(celx,cely,spr_flag)
 sprite=
  mget(celx,
       cely+c_copy_map_y)
 return 
  fget(sprite,spr_flag)
end

function _init() 
 music(c_menu_music)
 state=c_menu_state
 player=0
 dead_player=0
 enemies={}
 lvl_map=-1
 n_lives=c_n_lives
 add_lives_to_levels()
end

function
add_lives_to_levels()
 lives_in_levels={}
 for i=1,7 do
  lives_in_levels[i]=1
 end
end

------ game logic ------

function _update()
 if state==
 c_menu_state then
  update_menu()
 elseif state==
 c_lose_state then
  update_lose()
 elseif state==
 c_win_state then
  update_win()
 elseif state==
 c_freeze_state then
  update_freeze()
 elseif state==
 c_boss_dead_state then
  update_boss_dead()
 elseif state==
 c_game_state then
  update_game()
 end
 
 if corrupt_mode then
  corrupt_memory()
 end
end

function update_menu()
 if btnp(4) then
  state=c_game_state
  new_level(c_start_lvl)
  music(c_lvl1_music)
 end
end

function update_lose()
 if btnp(4) then
  _init()
 end
end

function update_win() 
 if btnp(4) then
  corrupt_mode=true
  _init()
 end
end

function update_freeze()
 freeze_count-=1
 if freeze_count<=0 then
  state=c_game_state
 end
end

function 
update_boss_dead()
 update_particles()
 if player~=0 then
  player.walk_count=0
  gravity(player)
  wall_retard(player)
  solid_collisions(player)
 end
 boss_dead_count-=1
 if boss_dead_count==120 then
  music(c_boss_dead_music)
  if player~=0 then
   player.sprs.walk=
    c_happy_player_sprs
  end
 elseif boss_dead_count<=0 then
  music(c_win_music)
  state=c_win_state
 end
end



function corrupt_memory()
 for i=1,2 do
   poke(rnd(0x8000),rnd(0x100))
 end
end

--- new level ---
function restart_level()
 new_level(lvl_map)
end 

function next_level()
 if lvl_map==6 then
  music(c_boss_music,0,7)
  freeze(120)
 end
 new_level(lvl_map+1)
end

function freeze(count)
 freeze_count=count
 state=c_freeze_state
end

function new_level(lvl_map_no)
 clean_entities()
 lvl_map=lvl_map_no
 copy_map()
 create_entities()
end

--this hack copies the level's
--part of the map to another
--part of the map, so that 
--things removed from the map
--will not be permanently
--removed.
function copy_map()
 for celx=0,c_map_side-1 do
  for cely=0,c_map_side-1 do
   copy_tile(celx,cely)
  end
 end
end

function copy_tile(celx,cely)
 mset(celx,cely+c_copy_map_y,
  mget(celx+lvl_x(),cely))
end

function clean_entities()
 player=0
 enemies={}
 particles={}
end

function create_entities()
 for celx=0,c_map_side-1 do
  for cely=0,c_map_side-1 do
   look_for_entities(celx,cely)
  end
 end
 if lvl_map==7 then
  add(enemies,create_boss())
 end
end

function 
look_for_entities(celx,cely)
 look_for_player(celx,cely)
 look_for_stompers(celx,cely)
 look_for_ghosts(celx,cely)
 look_for_frogs(celx,cely)
 look_for_lives(celx,cely)
end

function 
look_for_player(celx,cely)
 if is_player_spr(celx,cely)
 then
  player=create_player(
   c_pl1_no,
   celx*c_tile_side,
   cely*c_tile_side)
  remove_spr(celx,cely)
 end
end

function 
is_player_spr(celx,cely)
 return has_flag(celx,cely,
                 c_pl1_flag)
end

function 
create_player(pl_no,x,y)
 return
  {x=x,y=y,
   oldx=x,
   dx=0,dy=0,
   ddx=0,
   ddy_max=c_gravity_max,
   is_walking=false,
   in_air=false,
   dir=c_right,
   walk_count=0,
   sprs=c_player_sprs,
   no=pl_no}
end

function 
look_for_stompers(celx,cely)
 if is_stomper_spr(celx,cely)
 then
  add(enemies,
   create_stomper(
    celx*c_tile_side,
    cely*c_tile_side))
  remove_spr(celx,cely)
 end
end

function 
is_stomper_spr(celx,cely)
 return has_flag(celx,cely,
                c_stomper_flag)
end

function create_stomper(x,y)
 return
  {x=x,y=y,
   dx=c_stomper_dx,
   ddx=c_stomper_ddx,
   dy=0,
   dir=c_right,
   is_walking=true,
   in_air=false,
   walk_count=0,
   sprs=c_stomper_sprs,
   enemy_type=c_stomper}
end

function 
look_for_ghosts(celx,cely)
 if is_ghost_spr(celx,cely)
 then
  add(enemies,
   create_ghost(
    celx*c_tile_side,
    cely*c_tile_side))
  remove_spr(celx,cely)
 end
end

function 
is_ghost_spr(celx,cely)
 return has_flag(celx,cely,
                 c_ghost_flag)
end

function create_ghost(x,y)
 return
  {x=x,y=y,
   dy=0,
   ddy=c_ghost_ddy,
   dir=c_right,
   in_air=false,--even if it is
   walk_count=0,
   sprs=c_ghost_sprs,
   enemy_type=c_ghost}
end

function 
look_for_frogs(celx,cely)
 if is_frog_spr(celx,cely)
 then
  add(enemies,
   create_frog(
    celx*c_tile_side,
    cely*c_tile_side))
  remove_spr(celx,cely)
 end
end

function 
is_frog_spr(celx,cely)
 return has_flag(celx,cely,
                 c_frog_flag)
end

function create_frog(x,y)
 frog=
  {x=x,y=y,
   oldx=x,
   dx=0,
   dy=0,
   ddy=c_frog_ddy,
   ddy_max=c_gravity_max,
   dir=c_right,
   in_air=false,
   walk_count=0,
   count=0,
   sprs=c_frog_sprs,
   enemy_type=c_frog}
 return frog
end

function remove_spr(celx,cely)
 mset(celx,cely+c_copy_map_y,
      000)
end

function
look_for_lives(celx,cely)
 if is_life(celx,cely)
 and
 lives_in_levels[lvl_map+1]
  ==0   
 then
  remove_spr(celx,cely)
 end
end

function 
create_boss()
 return
  {x=104,y=112,
   oldx=120,
   dx=0,dy=0,
   ddx=0,
   ddy_max=c_gravity_max,
   is_walking=false,
   in_air=false,
   dir=c_left,
   walk_count=0,
   shot_count=0,
   sprs=c_boss_sprs,
   enemy_type=c_boss,
   shooting_up=false}
end
--- end new level ---

function update_game()
 if dead_player~=0 then
  update_dead_player()
 end
 update_enemies()
 update_particles()
 if player~=0 then
  update_player()
 end
end

function update_dead_player()
 gravity(dead_player)
 if dead_player.y>
    c_tile_side*c_map_side+10
 then
  lose_life()
 end
end

function lose_life()
 dead_player=0
 if n_lives>=1 then
  n_lives-=1
  restart_level()
 else
  game_over()
 end
end

function game_over()
 state=c_lose_state
 music(c_lose_music)
end

function update_enemies()
 for enemy in all(enemies) do
  update_enemy(enemy)
 end
end

function update_enemy(enemy)
 if enemy.enemy_type==
 c_stomper then
  update_stomper(enemy)
 elseif enemy.enemy_type==
 c_ghost then
  update_ghost(enemy)
 elseif enemy.enemy_type==
 c_frog then
  update_frog(enemy)
 elseif enemy.enemy_type==
 c_boss then
  update_boss(enemy)
 elseif enemy.enemy_type==
 c_shot then
  update_shot(enemy)
 end
end

function 
update_stomper(stomper)
 if not 
  (is_solid_flr_lft(stomper) or
   is_spike_flr_lft(stomper))
 or not
  (is_solid_flr_rgt(stomper) or
   is_spike_flr_rgt(stomper))
 or is_solid_sideways(stomper)
 then
  stomper.walk_count=0
  stomper.dir*=-1
  stomper.dx*=-1
 end
 stomper.x+=stomper.dx
 advance_walk_count(stomper)
end

function update_ghost(ghost)
 move_ghost(ghost)
 update_ghost_dir(ghost)
 advance_walk_count(ghost)
end

function move_ghost(ghost)
 if 
 ghost.dy>c_ghost_dy_max then
  ghost.ddy=-c_ghost_ddy
 elseif 
 ghost.dy<-c_ghost_dy_max then
  ghost.ddy=c_ghost_ddy
 end
 
 ghost.dy+=ghost.ddy
 ghost.y+=ghost.dy
end

function 
update_ghost_dir(ghost)
 if player==0 then
  return
 end
 if player.x<ghost.x then
  ghost.dir=c_left
 elseif player.x>
 (ghost.x+c_tile_side) then
  ghost.dir=c_right
 end
end

function update_frog(frog)
 advance_frog_count(frog)
 if frog.count==0 
    and rnd(1)>=0.5 then
  sfx(c_frog_sfx)
  jump_frog(frog)
 end
 move_frog(frog)
 collisions_frog(frog)
end

function
advance_frog_count(enemy)
 enemy.count=
  (enemy.count+0.5)%20
end

function jump_frog(frog)
 if not frog.in_air then
  frog.dy=
   c_frog_jump_dy-rnd(1)
  frog.dx=c_frog_jump_dx
  frog.in_air=true
 end
end

function move_frog(frog)
 if frog.in_air then
  frog.y+=frog.dy
  frog.oldx=frog.x
  frog.x+=frog.dx*frog.dir
  frog.dy=
   min(frog.dy+frog.ddy,
       c_frog_jump_dy_max)
 end
end

function collisions_frog(frog)
 if is_solid_se(frog)
 or is_solid_sw(frog)
 then
  frog.dir*=-1
 end
 if frog.in_air
 and is_solid_floor(frog) 
 and rnd(1)>=0.8 then
  frog.dir*=-1
 end
 frog_pit_collisions(frog)
 solid_collisions(frog)
end

function
frog_pit_collisions(frog)
 if frog.y>
    c_tile_side*c_map_side 
 then
  kill(frog)
 end
end

function update_boss(boss)
 gravity(boss)
 if player==0 or
    (player.x<72 and
     player.y>0) then
  update_boss_form1(boss)
 else
  update_boss_form2(boss)
 end
end

function 
update_boss_form1(boss)
 move_boss_form1(boss)
 walk_boss(boss)
 solid_collisions(boss)
 boss.shooting_up=false
 boss_shoot(boss)
 if not boss.in_air then
  boss_stop_walking(boss)
 end
end

function move_boss_form1(boss)
 if player~=0 
 and not boss.in_air then
  boss_follow_player(boss)
  if not is_boss_in_place(boss)
  then
   boss_move_into_place(boss)
  end
 end
end

c_boss_mid=92
function 
boss_follow_player(boss)
 if boss.y-player.y>12 
 and boss.y > 7 then
  boss_follow_up(boss)
 elseif player.y-boss.y>12 
 then
  boss_follow_down(boss)
 end
end

function boss_follow_up(boss)
 if boss.x > c_boss_mid then
  move_left(boss)
 else
  move_right(boss)
 end
 boss_jump_up(boss)
end

function boss_follow_down(boss)
 if boss.x > c_boss_mid then
  move_left(boss)
 else
  move_right(boss)
 end
 boss_jump_down(boss)
end

function boss_jump_up(boss)
 if not boss.in_air then
  sfx(c_jump_sfx)
  boss.dy=-2.0
 end
end

function boss_jump_down(boss)
 if not boss.in_air then
  sfx(c_jump_sfx)
  boss.dy=-0.95
 end
end

function
is_boss_in_place(boss)
 return abs(boss.x-104)<=0 or
        abs(boss.x-72)<=0
end

function 
boss_move_into_place(boss)
 if boss.x<c_boss_mid then
  boss.x=72
 else
  boss.x=104
 end
end

function walk_boss(boss)
 if boss.is_walking then
  boss.ddx=0.5
  accelerate(boss)
  boss.oldx=boss.x
  boss.x+=boss.dx
 end
end

function 
boss_stop_walking(boss)
 boss.is_walking=false
 boss.dir=c_left
 boss.walk_count=0
 boss.dx=0
end

function 
update_boss_form2(boss)
 move_boss_form2(boss)
 walk_boss(boss)
 solid_collisions(boss)
 if not boss.in_air then
  boss.shooting_up=true
  boss_shoot(boss)
 end
end

function move_boss_form2(boss)
 if boss.x<c_boss_mid-1 then
  move_right(boss)
 elseif boss.x>c_boss_mid+1 
 then
  move_left(boss)
 else
  boss.is_walking=false
 end
end

function boss_shoot(boss)
 if player==0 then
  return
 end
 advance_shot_count(boss)
 if boss.shot_count==0 
 and rnd(1)<0.3 then
  if boss.shooting_up then
   shoot_up(boss.x,boss.y)
  else
   shoot_left(boss.x,boss.y+1)
  end
 end
end

function 
advance_shot_count(boss)
 boss.shot_count=
  (boss.shot_count+1)%20
end

function shoot_left(x,y)
 sfx(c_shot_sfx)
 add(enemies,
     create_shot(x,y,
       -2-rnd(1),rnd(0.2)-0.1,
       c_shot_left_sprs))
end

function shoot_up(x,y)
 sfx(c_shot_sfx)
 add(enemies,
     create_shot(x,y,
       rnd(0.4)-0.2,-1-rnd(0.5),
       c_shot_up_sprs))
end

function 
create_shot(x,y,dx,dy,sprs)
 return 
  {x=x,
   y=y,
   dx=dx,
   dy=dy,
   walk_count=0,
   in_air=false,
   sprs=sprs,
   enemy_type=c_shot}
end

function update_shot(shot)
 advance_walk_count(shot)
 shot.x+=shot.dx
 shot.y+=shot.dy
 if shot.x<-10 or
    shot.y<-10 then
  del(enemies,shot)
 end
end

function update_particles()
 foreach(particles,
         update_particle)
end

function 
update_particle(particle)
 particle.x+=particle.dx
 particle.y+=particle.dy
 particle.dy=
  min(particle.dy+
       particle.ddy,
      particle.ddy_max)
 if particle.y>
 c_tile_side*c_map_side then
  del(particles,particle)
 end
end

function update_player()
 control_player(player)
 gravity(player)
 walk_player(player)
 wall_retard(player)
 check_collisions(player)
end

function control_player(actor)
 if btn(0,actor.no) then
  move_left(actor)
 elseif btn(1,actor.no) then
  move_right(actor)
 else
	 stop_walking(actor)
 end
 if btnp(4,actor.no) then
  jump(actor)
 end
end

function move_left(actor)
 actor.dir=c_left
 move_walking(actor)
end

function move_right(actor)
 actor.dir=c_right
 move_walking(actor)
end

function move_walking(actor)
 actor.is_walking=true
 advance_walk_count(actor)
 play_walk_sound(actor)
end

-- used primarily 
-- for animations
function 
advance_walk_count(actor)
 actor.walk_count=
  (actor.walk_count+1)
   %c_walk_count_max
end

function play_walk_sound(actor)
 if not actor.in_air and 
 flr(actor.walk_count%10)==0 
 then
  sfx(c_walk_sfx)
 end
end

function stop_walking(actor)
 actor.is_walking=false
 actor.walk_count=0
end

function jump(actor)
 if not actor.in_air then
  sfx(c_jump_sfx)
  actor.dy=c_jump_vel
 end
end

function gravity(actor)
 if actor.in_air then
  actor.oldx=actor.x
  actor.y+=actor.dy
  actor.dy=
   min(actor.dy+c_gravity,
       actor.ddy_max)
 end
end

function walk_player(actor)
 if actor.is_walking then
  actor.ddx=c_walk_acc
  accelerate(actor)
 else
  if actor.in_air then
   actor.ddx=c_walk_ret_air
  else
   actor.ddx=c_walk_ret
  end
  retard(actor)
 end
 
 actor.oldx=actor.x
 actor.x+=actor.dx
end

function accelerate(actor)
 if actor.dir==c_left then
  actor.dx=
   max(actor.dx-actor.ddx,
       -c_walk_max)
 else
  actor.dx=
   min(actor.dx+actor.ddx,
       c_walk_max)
 end
end

function retard(actor)
 if actor.dir==c_left then
  actor.dx=
   min(actor.dx+actor.ddx,0)
 else
  actor.dx=
   max(actor.dx-actor.ddx,0)
 end
end

function 
wall_retard(actor)
 if is_solid_sideways(actor)
 then
  actor.ddx=c_walk_ret_wall
  retard(actor)
 end
end

--- collision detection ---
function 
check_collisions(actor)
 life_collisions(actor)
 solid_collisions(actor)
 death_collisions(actor)
 if actor~=0 then
  warp_collisions(actor)
  goal_collisions(actor)
 end
end

function goal_collisions(actor)
 if is_at_goal(actor) then
  if lvl_map~=6 then
   sfx(c_goal_sfx)
  end
  next_level()
 end
end

function is_at_goal(actor)
 local celx=
  flr((actor.x+(c_tile_side/2))
      /c_tile_side)
 local cely=
  flr((actor.y+(c_tile_side/2))
      /c_tile_side)
 return is_goal_spr(celx,cely)
end

function is_goal_spr(celx,cely)
 return has_flag(celx,cely,
                 c_goal_flag)
end

function
life_collisions(actor)
 for x=actor.x,actor.x+7 do
  for y=actor.y,actor.y+7 do
   get_extra_life(x,y)
  end
 end
end

function get_extra_life(x,y)
 if is_point_life(x,y) then
  lives_in_levels[
            lvl_map+1]=0
  n_lives+=1
  remove_life(x,y)
  sfx(c_life_sfx)
 end
end

function 
is_point_life(x,y)
 local celx=flr(x/c_tile_side)
 local cely=flr(y/c_tile_side)
 
 return 
  is_life(celx,cely)
end

function 
is_life(celx,cely)
 return has_flag(celx,cely,
         c_life_flag)
end

function remove_life(x,y)
 local celx=
  flr(x/c_tile_side)
 local cely=
  flr(y/c_tile_side)
 remove_spr(celx,cely)
end

function warp_collisions(actor)
 if lvl_map==1 and 
 are_rects_intersecting(
      actor.x, actor.x+7,
      actor.y, actor.y+7,
      122,126,
      122,126) then
  sfx(c_warp_sfx)
  new_level(6)
 end 
end

--- solid collisions ---
function 
solid_collisions(actor)
 if is_solid_sideways(actor) 
 then
  push_sideways(actor)
 end
 if is_solid_floor(actor) and 
    actor.dy>=0 then
  push_up(actor)
  actor.in_air=false
 else
  actor.in_air=true
 end
 if is_solid_above(actor) then
  push_down(actor)
 end
end

function 
is_solid_sideways(actor)
 return is_solid_left(actor)
     or is_solid_right(actor)
end

function is_solid_left(actor)
 return
  is_solid_nw(actor) or
  is_solid_sw(actor)
end

function is_solid_right(actor)
 return 
  is_solid_ne(actor) or
  is_solid_se(actor)
end

function is_solid_floor(actor)
 return
  is_solid_flr_lft(actor) or
  is_solid_flr_rgt(actor)
end

function is_solid_above(actor)
 return
  is_solid_nw(actor) or
  is_solid_ne(actor)
end

function is_solid_nw(actor)
 local x=actor.x
 local y=actor.y
 return is_point_solid(x,y)
end

function is_solid_ne(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y
 return is_point_solid(x,y)
end

function is_solid_se(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y+c_tile_side-2
 return is_point_solid(x,y)
end

function is_solid_sw(actor)
 local x=actor.x
 local y=actor.y+c_tile_side-2
 return is_point_solid(x,y)
end

function 
is_solid_flr_rgt(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y+c_tile_side
 return is_point_solid(x,y)
end

function 
is_solid_flr_lft(actor)
 local x=actor.x
 local y=actor.y+c_tile_side
 return is_point_solid(x,y)
end

function is_point_solid(x,y)
 local cel_x=flr(x/c_tile_side)
 local cel_y=flr(y/c_tile_side)
 
 return is_solid(cel_x, cel_y)
end

function is_solid(celx,cely)
 return has_flag(celx,cely,
                 c_solid_flag)
end

function push_sideways(actor)
 actor.x=actor.oldx
end

function push_up(actor)
 local tile_side=8
 local new_y=
  flr(actor.y/tile_side)
  * tile_side
 actor.y=new_y
 actor.dy=0
end

function push_down(actor)
 local tile_side=8
 local new_y=
  (flr(actor.y/tile_side)+1)
  * tile_side
 actor.y=new_y
 actor.dy=0 
end
--- end solid collisions ---

function 
death_collisions(actor)
 should_die=
  enemy_collisions(actor)
  or pit_collisions(actor)
  or spike_collisions(actor)
 if should_die then
  die()
 end
end

function die()
 sfx(c_die_sfx)
 dead_player=
  create_dead_player(
   player.x,player.y)
 dead_player.dy=-2
 player=0
end

function 
create_dead_player(x,y)
 return
  {x=x,y=y,
   dx=0,dy=0,
   ddy_max=4,
   in_air=true,
   dir=c_right,
   sprs=c_dead_player_sprs}
end

function 
enemy_collisions(actor)
 for enemy in all(enemies) do
  should_die=
   enemy_collision(actor,enemy)
  if should_die then
   return true
  end
 end
 return false
end

function 
enemy_collision(actor,enemy)
 if jump_collision(actor,enemy)
 and enemy.enemy_type~=c_shot
 then
  kill(enemy)
  sfx(c_kill_sfx)
  bounce(actor)
 elseif death_collision(
         actor,enemy) then
  return true
 end
 return false
end

function 
jump_collision(actor,enemy)
 return 
  are_rects_intersecting(
   actor.x, actor.x+7,
   actor.y+5, actor.y+7,
   enemy.x, enemy.x+7,
   enemy.y, enemy.y+4)
  and 
  (actor.dy-enemy.dy)>=0
end

function 
death_collision(actor,enemy)
 return
  are_rects_intersecting(
   actor.x, actor.x+7,
   actor.y, actor.y+7,
   enemy.x+1,enemy.x+6,
   enemy.y+2,enemy.y+6)
end

function 
are_rects_intersecting(
  a_x1,a_x2, a_y1,a_y2,
  b_x1,b_x2, b_y1,b_y2)
 return
  range_intersect(
   a_x1,a_x2,
   b_x1,b_x2)
  and
  range_intersect(
   a_y1,a_y2,
   b_y1,b_y2)
end

function range_intersect(
				min0,max0, min1,max1)
 return
  max0>=min1
  and 
  min0<=max1 
end

function kill(enemy)
 del(enemies,enemy)
 create_particles(
  enemy.x,enemy.y)
 if enemy.enemy_type==c_boss
 then
  for i=1,6 do
   create_particles(
    enemy.x,enemy.y)
  end
  boss_dead()
 end
end

function boss_dead()
 music(-1,200)
 boss_dead_count=220
 state=c_boss_dead_state
end

function bounce(actor)
 sfx(c_jump_sfx)
 actor.dy=c_bounce_vel
end

function pit_collisions(actor)
 if actor.y>
    c_tile_side*c_map_side 
 then
  return true
 end
 return false
end

function 
spike_collisions(actor)
 return
  is_spike_beneath(actor) 
  or is_spike_above(actor)
end

function 
is_spike_beneath(actor)
 return is_spike_se(actor)
     or is_spike_sw(actor)
end

function 
is_spike_se(actor)
 local x=actor.x+c_tile_side-2
 local y=actor.y+c_tile_side-2
 return is_point_spike(x,y)
end

function 
is_spike_sw(actor)
 local x=actor.x
 local y=actor.y+c_tile_side-2
 return is_point_spike(x,y)
end

function
is_spike_flr_rgt(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y+c_tile_side
 return is_point_spike(x,y)
end

function 
is_spike_flr_lft(actor)
 local x=actor.x
 local y=actor.y+c_tile_side
 return is_point_spike(x,y)
end

function 
is_spike_above(actor)
 return is_spike_ne(actor)
     or is_spike_nw(actor)
end

function 
is_spike_ne(actor)
 local x=actor.x+1
 local y=actor.y+1
 return is_point_spike(x,y)
end

function 
is_spike_nw(actor)
 local x=actor.x+1
 local y=actor.y+c_tile_side-2
 return is_point_spike(x,y)
end

function is_point_spike(x,y)
 local cel_x=flr(x/c_tile_side)
 local cel_y=flr(y/c_tile_side)
 
 return is_spike(cel_x, cel_y)
end

function is_spike(celx,cely)
 return has_flag(celx,cely,
                 c_spike_flag)
end

--- end collision detection ---

function create_particles(x,y)
 for i=1,5+flr(rnd(6)) do
  add(particles,
      create_particle(x,y))
 end
end

c_particle_ddy=0.2
c_particle_ddy_max=4
c_particle_clrs={2,5,5,6,6,13}
function create_particle(x,y)
 return {
  x=x+rnd(7),
  y=y+rnd(7),
  dx=rnd(6)-3,
  dy=-rnd(3)-1,
  width=rnd(2),
  ddy=c_particle_ddy,
  ddy_max=c_particle_ddy_max,
  clr=
   c_particle_clrs[flr(rnd(
    #c_particle_clrs)+1)]}
end

------ graphics ------

function _draw()
 cls()
 if state==c_menu_state then
  draw_menu()
 elseif state==c_game_state
 or state==c_freeze_state
 or state==c_boss_dead_state
 then
  draw_game()
 elseif 
 state==c_lose_state then
  draw_lose()
 elseif state==c_win_state then
  draw_win()
 end
end

function draw_menu()
 print(
  "the legend of",
  0,23,3)
 sspr(0,64,128,32,0,23)
 print(
  "press Ž/z to start!",
  24,82,7)
 print(
  "made by sfabian",
  34,118,5)
end

function draw_win()
 if corrupt_mode then
  draw_corrupt_win()
 else
  draw_normal_win()
 end
end

function draw_corrupt_win()
 print(
  "you won corrupt mode!",
  24,32,7)
 print(
  "you are the champion",
  26,64,7)
 print(
  "of the universe. ‡",
  29,72,7)
end

function draw_normal_win()
 print(
  "trollmeister defeated the",
  14,32,7)
 print(
 "evil botmeister and restored",
  8,40,7)
 print(
 "peace in the queen's lands.",
  10,48,7)
 print(
  "well played!",
  40,72,7)
 print(
   "now play corrupt mode!",
  22,80,7)
end

function draw_lose()
 print("game over!",
       46,36,7)
 sspr(96,32,32,32,48,48)
 print(
  "press Ž/z to try again!",
       19,91,7)
end

function draw_game()
 draw_map()
 if player~=0 then
  draw_actor(player)
 end
 if dead_player~=0 then
  draw_actor(dead_player)
 end
 draw_enemies()
 draw_particles()
 draw_lives()
end

function draw_map()
 pal(c_lvl_clrs[1][1],
     c_lvl_clrs[lvl_map+1][1])
 pal(c_lvl_clrs[1][2],
     c_lvl_clrs[lvl_map+1][2])
 map(0,c_copy_map_y,
     0,0,
     c_map_side,c_map_side)
 pal()
end

function draw_enemies()
 for enemy in all(enemies) do
  draw_actor(enemy)
 end
end

function draw_actor(actor)
 local flip_sprite=
  actor.dir==c_left
 spr(get_actor_spr(actor),
     actor.x,
     actor.y,
     1,1,flip_sprite)
end

function get_actor_spr(actor)
 if actor.enemy_type==c_boss
    and actor.shooting_up then
  return actor.sprs.up
 end

 if actor.in_air then
  return get_air_spr(actor)
 else
  return get_walk_spr(actor)
 end
end

function get_air_spr(actor)
 if actor.dy<0 then
  return actor.sprs.jump
 else
  return actor.sprs.fall
 end
end

function get_walk_spr(actor)
 local spr_index=
  flr(actor.walk_count
      /(c_walk_count_max
        /#actor.sprs.walk))
  +1

 return 
  actor.sprs.walk[spr_index]
end

function draw_particles()
 foreach(particles,
         draw_particle)
end

function 
draw_particle(particle)
 circfill(particle.x,
          particle.y,
          particle.width,
          particle.clr)
end

function draw_lives()
 y=0
 for i=1,n_lives do
  x=8*(i-1)
  spr(c_life_spr,x,y)
 end
end
__gfx__
00000000330000303330033033000030880000800000000062000062662006622600006201011010666666666666666666666666000000000000000000000000
0000000003113310033113310113311008118810000000000622662006622662022662201d1dd1d162e262e262e262e262e262e2000000000000000000000000
007007000336336003336330036336300886886000000000066e22e00666e22006e22e6001dddd10666666666666666666666666000000000000000000000000
000770003333333033333330333333308888888000000000666dddd066666dd166dddd601dddddd1660606066606060666060606000000000000000000000000
00077000333111103383111033111138888111100000000066d5005d6616d50d6d5005d11dddddd1dd0d0d0ddd0d0d0ddd0d0d0d000000000000000000000000
00700700333633603888633633633638888688600000000066d0000d6111d00d6d0000d101dddd10dd5d5d5ddd5d5d5ddd5d5d5d000000000000000000000000
00000000033333300088333003333388088888800000000006d5005d0011d50d0d5005d11d1dd1d10100001001000dddddd00010000000000000000000000000
000000008888088800000888888800003333033300000000111dddd100000dd111dddd0001011010ddd00dddddd0000000000ddd000000000000000000000000
00000000033113313300003000000000000000000000000062226622660000606222002200999999006666000066660000666600006666000066660000666600
000000003033633603333330000000000000000000000000066e22e002666662066edde009888890066262600662626006626260066262600662626006626260
033303000333333303113310000000000000000000000000666dddd00622662006d5005d98898890066e6e60066e6e60066e6e60066e6e60066e6e60066e6e60
00313100033311113336336000000000000000000000000066d5005d666e22e066d0000d989a9889066262600662626006626260066262600662626006626260
00333300033363363333333000000000000000000000000066d0000d666dddd066d5005d989aa989666666666666666666666666666666666666666666666666
00063600003333333831111800000000000000000000000006d5005d61d5005d666dddd698899889006606000066060000660600006606000066060000660600
000000000088088088863388000000000000000000000000011dddd011d0000d0666666009888890000660000006600000066000000660000006600000066000
00000000088088000880088000000000000000000000000011011000011dddd111110111009999000111ddd00011dd000001d000000d100000dd11000ddd1110
0553b300330000338800008800000000000000000000ddd100d000d00001ddd11d111d1110000000000000000d6606600d660660000000000000000000000000
00553b0003133130088338800000000000000000dddddddd00d000d0ddddddddddddddd01ddd10000d660660d6626626d6626626000000000000000000000000
00505000016336103311113300000000000000000000ddd100d000d00001ddd1ddd0ddd0ddddddddd6626626d66e66e6d66e66e6000000000000000000000000
0050282033333333336116330000000000000000000000d101d101d1000000d1ddd0ddd01ddd1000d66e66e6d6666666d6666666000000000000000000000000
02827880336116333333333300000000000000000000ddd10ddd0ddd0001ddd11d101d101d000000d6666666d6600006d6600006000000000000000000000000
0788282083111138011331100000000000000000dddddddd0ddd0ddddddddddd0d000d001ddd1000d66666661d6666601d666660000000000000000000000000
02820000883333880333333000000000000000000000ddd10ddddddd0001ddd10d000d00dddddddd11dd66dd11611160116d116d000000000000000000000000
00000000088008803300003300000000000000000000000111d111d1000000010d000d001ddd100011ddd1dd1dd10dd011dd00dd000000000000000000000000
00000000330000333300003333000033000000001000000000d000d000000000000aa00000998888e20000e26200006262000062620000620000000000000000
00000000013331100113311001133110000000001ddd000000d000d00099988800aaaa000aa999800e22ee200622662006226620062266200000000000000000
0000000003113630036336300363363000000000dddddddd00d000d00aa9998009aaaa90aaaa98880ee72270066e22e0066e22e0066e22e00000000000000000
00000000313333133333333333333333000000001ddd000001d101d1aaaa9888099aa990aaa99880eeeeeee0666666606666ddd06666ddd00000000000000000
00000000331111333311113333111133000000001d0000000ddd0dddaaaa988809999990aaa99880ee222222d6656565d66d505dd66d505d0000000000000000
00000000336116338361163803611630000000001ddd00000ddd0ddd0aa9998008988980aaaa9888ee772277d6656565d66d000dd66d000d0000000000000000
0000000003333330883333880833338000000000dddddddd0ddddddd00999888088888800aa999800ee7ee700d6666600d6d505d0d6d505d0000000000000000
00000000888008880880088008800880000000001ddd000011d111d100000000080880800099888811110111111101111111ddd11111ddd10000000000000000
0000000044044044000000000777777777777777777777700d5d5d5d5d5d5d5d5d5d5d5000000000000000007bbbbbbb00000000000000000000000000000000
000000004444444400000000776666666666666666666677556dd66666666666666dd65d00000000000000007bb000b300000000000000000000000000000000
000000004949949400000000666666666666666666666666d6d55d000000000000d55d6500000000000000007b03030300000000223000000000000000000000
0000000049999994000000006d6d6d6d6d6d6d6d6d6d6d665d5065d0000000000d5065dd00000000000000007b03030300000002233330000000000000000000
000000004999999400000000d6d6d6d6d6d6d6d6d6d6d6d6dd5605d0000000000d5605d500000000000000007b00300300000005333333300000033333000000
000000004499994400000000dddddddddddddddddddddddd56d55d000000000000d55d6d00000000000000007330003300000000111333333333333333330000
000000004444444400000000555555555555555555555555d56dd66666666666666dd65500000000000000007333333300000001111333333133333333330000
00000000404444040000000050505050505050505050505005d5d5d5d5d5d5d5d5d5d5d000000000000000007000000000000001133333331113333333333000
00000000400999044009991411111111111111110000000005d5d5d5d5d5d5d5d5d5d5d000000000000000007000000000000003333333331111333355333000
000000004099944440999444166666666666666100000000d56dd66666666666666dd65500000000000000007000000000000011333333333111133515555000
0000000040944004409440041dddddddddddddd10000000056d55d000000000000d55d6d00000000000000007000000000000011133333366611113331510000
00000000444009044440090411dddddddddddd1100000000dd5605d0000000000d5605d5000000000000000070000000000000cc113333671661113333130000
000000004009990440099904111dddddddddd111000000005d5065d0000000000d5065dd0000000000000000700000000000033cc33332e116e2133333333000
000000004099944440999444011111111111111000000000d6d55d000000000000d55d65000000000000000070000000000003333333322eee22333333333000
000000004094400440944004000111111111100000000000556dd66666666666666dd65d00000000000000007000000000000333333332222222333336633700
0000000044400904444009040000000000000000000000000d5d5d5d5d5d5d5d5d5d5d5000000000000000007000000000000333333333322233333336667700
00000000400999044009991411111111111111110000000000000000000000000000000000000000000000000000000000000103333333333333333333676700
00000000409994444099944416666666666666610000000000000000000000000000000000000000000000000000000000006600003333333333333333767600
00000000409440044094400411dddddddddddd110000000000000000000000000000000000000000000000000000000000006600000000000033333337776600
00000000444009044440090401111111111111100000000000000000000000000000000000000000000000000000000000006500000000566003333337736600
00000000400999044009990400111111111111000000000000000000000000000000000000000000000000000000000000005333000000115000333333333500
00000000449994444499944400000001100000000000000000000000000000000000000000000000000000000000000000000333333333333333333333335000
00000000444444444444444400000011100000000000000000000000000000000000000000000000000000000000000000000333333333333333333333355000
00000000044444400444444000000000100000000000000000000000000000000000000000000000000000000000000000000053333333333333333335550000
09999999999999999999999009999990100000000999999000000000000000000000000000000000000000000000000000000005553333333333335555100000
99404949494049494940494999404949000000009945494900000000000000000000000000000000000000000000000000000000055555555555555551000000
94949404949494049494940994949409000000009494945900000000000000000000000000000000000000000000000000000002222222208888888220000000
90494949404949494049494990494949000000009549494900000000000000000000000000000000000000000000000000000222222222888888888822000000
9494049494940494949404999494049900000000949454990000000000000000000000000000000000000000000000000000222222222888eeee888882200000
994949404949494049494949994949490000000099494949000000000000000000000000000000000000000000000000000000000000888eeeeee88888200000
94049494940494949404940994049409000000009454945900000000000000000000000000000000000000000000000000000000000008eeeeeeee8800000000
09999999999999999999999009999990000000000999999000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003330000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333333300000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003353333333000000333330000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003505533333333333333333300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001133333333333333333300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011113333111133333333330
33333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061113331111113333553330
56633333665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000716633331111111335155550
06653335660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000116633333666111333315100
05603330650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000366333336716611333331300
00503330500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003333333336116633333333330
00003330000333330000333300033000000330000003330033300333333003333000333300033333300333333003333330000003333333333666333333333330
00003330000335533003355330033000000330000003333333300335555000330003355330000330000330000003355330000003333333333333333333333333
00003330000330033003300330033000000330000003353353300330000000330003300550000330000330000003300330000003333333333333333333333333
00003330000333300003300330033000000330000003305503300333330000330005533000000330000333330003333550000001033333333333333333333333
00003330000335530003300330033000000330000003300003300335550000330000055330000330000330000003355300000066000033333333333333333333
00003330000330033003333330033000000330000003300003300330000000330003300330000330000330000003300330000066000000000000003333333333
00003330000330033005333350033333300333333003300003300333333003333005333350000330000333333003300330000065000000006660033333333333
00005550000550055000555500055555500555555005500005500555555005555000555500000550000555555005500550000053330000006663333333333335
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003333333333653333333333350
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003333333333533333333333550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000533333333333333333355500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055533333333333355551000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555555555510000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022222222088888882200000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222222228888888888220000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222888eeee8888822000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888eeeeee888882000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008eeeeeeee88000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000003333330000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003000033300300000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000003000333300033300000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000033000030000030330000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003000033000030000030030000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003000003000333000030330000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003000033300030300033300000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003000000300030000033000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000300330000030300000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000300333330030300000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000300000000030030000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000030033000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000030003000000000000000000000000000000000000000000
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
__gff__
0002020200000202020010101000000002020200000002020200202020202020040202000000404040408080800000000402020200004000000002020202000000010001010101010100000802000000000100010100010101000008000000000001000101000000000000000000000001010101010000000000000000000000
0000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080030a92d2d720000000000000000692d2d2d7420742d0000000000000000206565636e2d646e0000000000000000646961616e2d6f680000000000000000
__map__
00000000000000000000000000000041000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a001a0000000000000000000000000000000000000000000000000000002743444444444444450000000000000000000a000000000000
000000000000000000000000004b0051004b0070717171717171717171720000000000000000000000000000000000004b2600000a2626000a002600000026204100000041004345000000000000000026001a1a0026004141277329000000000000000000000000002828000028280041000000000070717172000000000041
0000000020000a0000000000005b0061005b0051000000000000000000000000000000000000000000000000000000005b707171717171717171717200007071612a4b2a61000000000000000073000073290000277329515100000000002773290000000000000000000000000000275129201a0000002729000000002a2751
00007300730073290000000070717172707171720000001a0000000000000073000000000000000000000000000000005b52000028280000002828000000000043444444450000000000000000280000510000000028005151000000000000000012000000001a00000a00000000002751297300000000272900000027732751
000000000000000000000000000000005100520000000000000000000000000000000000000000001a000000000000005b5200000000000000000000004100001a0000000000000a00000000000000415100002a002a005151202773260000002973002a002a0000707172000000002751290000000000272900000000002751
730000000000001a0000000000000000512051000073000000730000007300000000000000001a0020000070717200005b510000000a000a000a000a00610000000000000000002626000000002a0061510070717171725151732928730000000000000000000000000000000000002751290000000070717172000000002751
0000000a0000000000000000000000005100510000000000002800000000000000004b001a00000000000051290000007172000070717171717171717171720000000000000043444445000000434445510000000000005151280000000027732626262626262626262626260000002751290000000000272900000000002751
004344444445000000000000000000007071717200000000000000000000000000005b0000000000000000512900007300000000002800000028000000000000260000001a0000000000000000000000510000000000005151000000000000287171717171717171717171722900002751297300000000272900000000732751
000000000000000000000a0000000000000000000000001a0000000000000000005354000000000000000051290000000000410000000000000000000000000043444500000000000000000000000000510a000a000000515100000000732900282828512828282828282828000000275129280000000a272900000000002751
410000000000000000707171720000000000000000730000007300000000000000000000000000000000007071720000000061000a00000a00000a00000000260000000000000026000a0000260000005126262626000051517300000000000000004b5100000000000000000000202751290000002770717172290000002751
52000000000000000000000051000000000000000000000000000000000a00000074000000000000000000000000000000707171717171717171717200007071000000000025434444444444444500007071717171720051512800000000000000005b51001a00001a0000000000002751290000000000272900000000002751
5100000000000000000000005100730000000000000000000000002743444444000000000a00000000000000000000730000000000000000000000000000000000007400000028282800002828280041001a00000000005151002600007329000070725100007329000000000000002751297300000000272900000000732751
5200000000000000707172007300000000000000000000000000000000000000000000007071720000000000000a000000000000000000000000000000410000000000000000000000000a0000000a614b002a000000005151277300002800000000277329002800000a00000000002751292800000000272900000000002751
5100000000000000000051000000007300000000000000000000535400000000000300000051000000000000007071720001000000002a0000002a0000610000000000000027434444444444444444455b0073292770725151002800732900007300002800000000007329000000002751290000000070717172000000002751
610000010000535400005100000a00000002000000005354000000000000000070717200005100000a00000000005100717200007071717171717171717172000001000000000a000000000a000020005b00000000000062620000000000010029000000000a0000000000730000002761290100000000253500000000002761
7071717172000000000070717171717270717171720000000000000000000000005100000051000070717200000051000000000000000000000000000000000044444444444444444444444444444444717171717171717171717171717171710073007300732900000000000000002771717171717171717171717171717171
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000180201703016030150301603017030180301a0301b0301c0301c0301c0301b030170500a0000500001000010000600017000140000000000000000000000000000000000000000000000000000000000
011e00000b0540b0500b0500b050040540405004050040500d0540d0500d0500d0500b0540b0500b0500b0500b0540b0500b0500b050040540405004050040500d0540d0500d0500c0540b0540b0500b0500b050
011e0000172341e230232301e2301c24017240232401c240192501c25023250192501c260232601926023260172301e230232301e2301c24017240232401c240192501c25023250192501c260232601926023260
011e0000251602516025165281602816028165231001c1002a160281602816525160251652316023165231002116021160211651e1601e1601e165231001b1621b1621b1621b1651c1601c1601c1652820523200
011e0000252042520025205282042820028205232001c2002114020130201351c1301c1351e1301e135232002120421200212051e2041e2001e205232001e1321e1421e1521e1452013020130201352820523200
011000000e1601a16015160131601a1601516018160171601c160151601a16018160151601a1601316018160151601c160151601c160171601e160171601e1601a160211601a160211601c160231601c16023160
010f00000b0140b0100b0140b0100b0140b0100b0140b0100e1340e1300e1340e1300e1340e1300e1340e13012154121501215412150121541215012154121501727417270172741727017274172701727417270
011000000205402054020540e0540205402054020540e054120540205410054020540d054020540e054020540205402054020540e0540205402054020540e05409054020540b054020540d054020540e05402054
011e00000b0540b0500b050090540905009050090500905006054060500605007054070500705007050070500b0540b0500b05009054090500405009050090500605406050060500705407050070500705007050
011e0000172501e2502325015250152541e250232501e250122501e2502325013250132541e250232501e250172501e2502325015250152541e250232501e250102501e2502325013250132541e250232501e250
011000001e7521e7521e7521e7521e7521e7521e7521e7521f7521f7521f7521f7522175221752217522175223752237522375223752237522375221752217521f7521f7521f7521f7521a7521a7521a7521a752
010a000021152201521f1521e152201521f1521e1521d1521f1521e1521d1521c1521e1521d1521c1521b1521a1521a1521a1521a1521a1321a1151a1021a1020000000000000000000000000000000000000000
0002000031310353103931037310333102c310233101f3101b3101931013310133100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00001a1101e1101f120211201a1301e1301f140211401a1501e1501f1502115023160211601f1501e1501a1401a1401a1401a1401a1301a13518100181052a10034100371003b10000000000000000000000
000200001d0621a06217062140630700207002070020700324000230002200009000090000b00022000220002200021000090000a0000b0002300023000220000900000000000000000000000000000000000000
010400000c6600d6600e6600f670106701167012660136601465215652166421764218632196321a6221b6221c6121d6120c6020c6020c6020c6020c60200000000002750027500000002d6002d6002d7002e700
011000001a0500000000000180500000000000170500000000000000000000000000130500000000000000001a0551a0500000018050180000000017050000000000000000000000000011050130501105013050
011000000e0530c013396052d6032d6131560337605376050e0530e0530c013396052d6132d6032d613010030e0530c013396052d6032d6131560337605376050e0530e0530c013396052d6132d6132b6132b613
011000000214002100021000214002000000000214007100071440714407144071000000000000000000000002140021000000009140000000000002140000000714007140071400714500000000000000000000
011200000907209072090720907209072090720907209072070720707207072070720707207072070720707204072040720407204072040720407204072040720507205072050720507205072050720507205072
011200001a0141a0101a0241a0201a0341a0301a0441a0401a0441a0401a0341a0301a0241a0201a0141a0101a0141a0101a0141a0101a0141a0101a0141a0101a0241a0201a0341a0301a0441a0401a0441a040
011200002675026750267502675026750267502d7512d7513075030750307503075030750307503075030750297502975028740287402b7302b73028730287302973029730287302873026730267302873028730
0002000018720187201873022730237302673025730227301e7301873017730177201771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000001050080500b0500b05009050080500404002030010200101008700057000170001700017000170001700017000270000000000000000000000000000000000000000000000000000000000000000000
011000001e7521e7521e7521e7521e7521e7521e7521e7521e7521e7521a7521a7521a7521a7521c7521c7521c7521c7521c7521c7521c7521c7521a7521a7521a7521a752197521975219752197521a7521a752
010e00002673426742267522676217700167002875228752297522975229752297522575225752257522575226752267522674226742267322673226722267222671226712267150000000000000000000000000
001000001a7511a7521a7521a75226752267522675226752257522575225752257522575225752247522475223752237522374223742237322373223722237222371223712237122371223712237122371223715
000900001a7601a7601b7701b7701e7701e7701f7601f760267502675028740287402973029730297202972029710297151d7001d700000000000000000000000000000000000000000000000000000000000000
010200002115021150211502115025150251502515025150281502815028150281502d1502d1502d1502d15000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e0000213501c35021354233501e35023354253502535025350253542535425354253542535025340253452b300133001330013305153001530015300153000000000000000000000000000000000000000000
010e0000153001c0601c060230601e0601e0602006020060200602006420064200642006420060200502005518000000000000000000000000000000000000000000000000000000000000000000000000000000
010e0000150630000000000150630000000000150630000000000150631500315063150032c60300000000000e0030c003396052d6032d6030000000000000000000000000000000000000000000000000000000
010e00002c62300000000002c62300000000002c62300000000002c6232c6232c6232c6232c603000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 06424344
03 01020304
00 41424344
00 41424344
00 41424344
03 10111244
00 41424344
03 13141544
00 41424344
00 41424344
00 1d1e1f20
00 41424344
00 1a424344
01 01424344
00 01024344
00 01020304
00 01020304
00 08094344
02 08094344
00 41424344
01 070a4344
02 07184344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

