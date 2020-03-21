# Terrain rendering demo for DragonRuby
# (C) 2020 Vidar Hokstad <vidar@hokstad.com>
# MIT licensed.

# This is a very rough and **slow** proof of concept.

$tiletypes = {
  "g" => "grass",
  "w" => "water",
  "r" => "rock",
  nil => "default"
}

# Array of arrays of height values.
$map = [
  "0w0w0w0w0g0g0g0g0w",
  "0w0w0w0w0g2r1r0g0w",
  "0w0w0w0w0g2r4r0g0w",
  "0w0w0w0g0g0g3g2g0w",
  "0w0g0w0g2g2g1g0g0g",
  "0w0w0w0g2g3g3g2g1g",
  "0g0g0w0g1g2g2g0w0w",
  "0g2g0w0w0w0w0w0w0w",
  "0w0w0w0w0w0w0w0w0w"
]


# Translate a map position into the screen coordinates,
# and the height value.
#
def pos(tilew, tileh, hmul, x,y)
  r = $map[y] || []
  my = 0
  tile = "grass"
  if r.is_a?(Array)
    my = r[x] || 0
  else
    # I apply a factor of 0.7 here, as pure
    # integer multiples of the tile height looks
    # odd. In a proper map representation I may
    # make the height much more granular.
    my = r[x*2].to_i * hmul.to_f * 0.7
    tile = $tiletypes[r[x*2+1]]
  end
  return (x-y)*tilew + 600, -(x+y)*tileh +540 + my*tileh, my, tile
end

# This renders a triangle (assuming the *tiles* actually represents
# two triangles), either left or right.
#
# (top_x,top_y) is the topmost corner, representing the map
#   coordinate.
# (
def render_half(args,out,top_x,top_y, side_x,side_y,bottom_y,offx,offslope, tile)

  tilew = args.state.tilew

  # Combined slope of the top and bottom lines of the triangle formed
  # by this half of the quad. Effectively the amount of
  # *shear* we apply to the triangle.

  slope  = (top_y+bottom_y-2*side_y)/(2*side_x-2*top_x)*tilew/64
  a = (0.5-slope) * 255 + 64
  a = 128 if a < 128

  # For each x positin in the triangle....
  xr = [top_x,side_x]
  (xr.min .. xr.max).each do |stripx|
    dx = (stripx-xr.min)*64/tilew
    h = (top_y-bottom_y)

    # ... render a 1 pixel wide strip of the tile texture.
    # "offslope" is an offset to account for rendering direction.
    out.sprites << {
      x: stripx,
      y: top_y-h-dx*slope+offslope*slope,
      w: 1,
      h: h,
      a: a,
      tile_x: offx+dx,
      tile_w: 1,
      path: "sprites/#{tile}.png"
    }
  end
end


def render_map(args, out)
  hmul  = args.state.height_multiplier
  tilew = args.state.tilew
  tileh = args.state.tileh

  out.solids << [0, 0, 1280, 720, 0,0,0, 255]
  $map.each_with_index do |row, y|
    max_x = row.length/2
    (0...max_x).each do |x|
      sx,  sy,  c, tile  = pos(tilew, tileh, hmul, x,  y)    # Top
      sx2, sy2, c2       = pos(tilew, tileh, hmul, x+1,y)    # Right
      sx3, sy3, c3       = pos(tilew, tileh, hmul, x  ,y+1)  # Left
      sx4, sy4, c4       = pos(tilew, tileh, hmul, x+1,y+1)  # Bottom

      # Uncomment if you want to see the map coordinate
      # args.outputs.labels << [sx, sy, "(#{x},#{y})"]

      if args.state.show_wireframe
        # Wireframe
        out.lines << [
          [ sx, sy, sx2, sy2],
          [ sx2, sy2, sx4, sy4],
          [ sx4, sy4, sx3, sy3],
          [ sx3, sy3, sx, sy]
          ]
      end

      if args.state.fill
        # "64" below refers to half the width of the tile sprites.
        render_half(args, out,sx,sy,sx3,sy3,sy4,0,64, tile)  # Left
        render_half(args, out,sx,sy,sx2,sy2,sy4, 64,0, tile) # Right
      end
    end
  end
end

def tick args  #end
  if args.state.tick_count == 0
    args.state.dirty = true
    args.state.tilew = 64
    args.state.tileh = 32
    args.state.height_multiplier = 1
    args.state.show_wireframe = true
    args.state.fill = true
  end

  if args.inputs.keyboard.key_up.l
    args.state.show_wireframe = !args.state.show_wireframe
    args.state.dirty = true
  end

  if args.inputs.keyboard.key_up.f
    args.state.fill = !args.state.fill
    args.state.dirty = true
  end

  if args.inputs.keyboard.key_up.h
    args.state.tileh = args.state.tileh == 32 ? 16 : 32
    args.state.dirty = true
  end

  if args.inputs.keyboard.key_up.w
    args.state.tilew = args.state.tilew == 64 ? 32 : 64
    args.state.dirty = true
  end

  if args.inputs.keyboard.key_up.m
    args.state.height_multiplier = args.state.height_multiplier == 1 ? 2 : 1
    args.state.dirty = true
  end


  if args.inputs.keyboard.key_up.r
    args.state.dirty = true
  end

  if args.state.dirty
    render_map(args,args.render_target(:map))
    args.state.dirty = false
  end

  args.outputs.sprites << [0, 0, 1280, 720, :map]
  args.outputs.labels << [10, 700, "#{args.gtk.current_framerate.to_i} fps"]
  args.outputs.labels << [10, 680, "Press 'l' to toggle wireframe (L)ines"]
  args.outputs.labels << [10, 660, "Press 'f' to toggle texture fill"]
  args.outputs.labels << [10, 640, "Press 'r' to force redraw (otherwise map is cached)"]
  args.outputs.labels << [10, 620, "Press 'h' to toggle tile height between 32px and 16px"]
  args.outputs.labels << [10, 600, "Press 'w' to toggle tile width between  64px and 32px"]
  args.outputs.labels << [10, 580, "Press 'm' to toggle mail height multiplier between 1 and 2"]
end
