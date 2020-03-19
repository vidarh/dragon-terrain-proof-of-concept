# Terrain rendering demo for DragonRuby
# (C) 2020 Vidar Hokstad <vidar@hokstad.com>
# MIT licensed.

# This is a very rough and **slow** proof of concept.

# Array of arrays of height values.
$map = [
  [0,0, 0,   2,   6, 0,0],
  [0,0, 0,   0,   2, 1,0],
  [0,0, 1.5, 1.5, 1, 1,0],
  [0,0, 1.5, 3.2, 3.2, 2, 0.8],
  [0,0, 1,   2,   2, 0,0],
  [0,0, 0,   0,   0, 0,0],
  ]

# The size of the tile *as rendered*
# Note that lots of things are likely to
# break if this isn't 2:1 **and** currently
# the code expects the sprites to be 128x128,
# and that probably also needs to change if
# these values change.
$tilew = 64.0
$tileh = 32.0

# Translate a map position into the screen coordinates,
# and the height value.
#
def pos(x,y)
  r = $map[y] || []
  my = r[x] || 0
  return (x-y)*$tilew + 640, -(x+y)*$tileh +500 + my*$tileh, my
end

# This renders a triangle (assuming the *tiles* actually represents
# two triangles), either left or right.
#
# (top_x,top_y) is the topmost corner, representing the map
#   coordinate.
# (
def render_half(out,top_x,top_y, side_x,side_y,bottom_y,offx,offslope, tile)

  # Combined slope of the top and bottom lines of the triangle formed
  # by this half of the quad. Effectively the amount of
  # *shear* we apply to the triangle.

  slope  = (top_y+bottom_y-2*side_y)/(2*side_x-2*top_x)

  # For each x positin in the triangle....
  xr = [top_x,side_x]
  (xr.min .. xr.max).each do |stripx|
    dx = stripx-xr.min
    h = (top_y-bottom_y)

    # ... render a 1 pixel wide strip of the tile texture.
    # "offslope" is an offset to account for rendering direction.
    out.sprites << {
      x: stripx,
      y: top_y-h-dx*slope+offslope*slope,
      w: 1,
      h: h,
      tile_x: offx+dx,
      tile_w: 1,
      path: "sprites/#{tile}.png"
    }
  end
end

def render_map(out)
  $map.each_with_index do |rows, y|
    rows.each_with_index do |col, x|
      sx,sy, c = pos(x,y)        # Top
      sx2, sy2,c2 = pos(x+1,y)   # Right
      sx3, sy3, c3 = pos(x,y+1)  # Left
      sx4, sy4,c4 = pos(x+1,y+1) # Bottom

      # Uncomment if you want to see the map coordinate
      # args.outputs.labels << [sx, sy, "(#{x},#{y})"]

      # Wireframe
      out.lines << [
        [ sx, sy, sx2, sy2],
        [ sx2, sy2, sx4, sy4],
        [ sx4, sy4, sx3, sy3],
        [ sx3, sy3, sx, sy]
        ]

      # Sine the map above does not encode tile type, I just select
      # by heiht for a simple test here.
      tile = (c == 0 && c2 == 0 && c3 == 0 && c4 == 0) ? "water" : "grass"

      render_half(out,sx,sy,sx3,sy3,sy4,0,$tilew, tile)  # Left
      render_half(out,sx,sy,sx2,sy2,sy4, $tilew,0, tile) # Right
    end
  end
end

def tick args
  if args.state.tick_count == 0
    render_map(args.render_target(:map))
  end

  args.outputs.sprites << [0, 0, 1280, 720, :map]
  args.outputs.labels << [10, 700, "#{args.gtk.current_framerate.to_i} fps"]
end
