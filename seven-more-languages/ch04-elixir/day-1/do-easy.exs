point1 = {1,2}
IO.puts "A 2D point: #{inspect point1}"

point2 = {10,0}
line1 = {point1, point2}
IO.puts "A line: #{inspect line1}"

# 10 is the radius
circle1 = {point1, 10}
IO.puts "A circle: #{inspect circle1}"

polygon1 = { {1,0}, {0,1}, {-1,0}, {0,-1} }
IO.puts "A polygon: #{inspect polygon1}"

triangle1 = { point1, point2, { -10, -10} }
IO.puts "A triangle: #{inspect triangle1}"
