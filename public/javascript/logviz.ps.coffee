paper.install window

arrow_head_left = null
arrow_head_right = null
arrow_to_self = null

paperSetup = (num_calls, num_events) -> 
  $("canvas").attr 'width', num_calls * 200
  $("canvas").attr 'height', num_events * 100
  paper.setup 'drawing_canvas'
  setupBackground num_calls, $("canvas").attr('height')

setupBackground = (num_calls, height) ->
  colors = ["#AAFFFF", "#AAFFAA"]
  for [0..num_calls-1]
    rect = new Rectangle new Point(_i*200, 0), new Point(_i*200+200, height)
    path = new Path.Rectangle rect
    path.fillColor = colors[_i%2]

setupArrowHeads = ->
  path = new Path
  path.add new Point 5,0
  path.add new Point 0,3
  path.add new Point 5,6
  path.strokeColor = 'black'
  arrow_head_left = new Symbol path
  path = new Path
  path.add new Point 0,0
  path.add new Point 5,3
  path.add new Point 0,6
  path.strokeColor = 'black'
  arrow_head_right = new Symbol path

setupArrowToSelf = ->
  path = new Path
  path.add new Point 0,0
  path.add new Point 40,0
  path.add new Point 40,20
  path.add new Point 0,20
  path.strokeColor = 'black'
  arrow_to_self = new Symbol path

drawArrow = (x1,x2,y) ->
  if x1 < x2 #Right-facing arrow
    line = new Path.Line(new Point(x1,y), new Point(x2,y));
    head = arrow_head_right.place [x2-3,y]
  else #Left-facing arrow
    line = new Path.Line new Point(x1,y), new Point(x2,y)
    head = arrow_head_left.place [x2+3, y]
  line.strokeColor = 'black'
    
  

drawCalls = (calls, height) ->
  roundingSize = new Size 10,10
  for call in calls
    rect = new Rectangle new Point(_i*200+25, call[1] - 40), new Point(_i*200+175, call[1])
    path = new Path.RoundRectangle rect, roundingSize
    path.fillColor = "#DDD"
    line = new Path.Line new Point(_i*200+100, call[1]), new Point(_i*200+100, call[2])
    line.strokeColor = '#000'
    text = new PointText new Point(_i*200+30, call[1] - 15)
    text.content = call[0]
    text.characterStyle =
      size: 20
      fillColor: 'black'

drawText = (x,y,string) ->
  text = new PointText new Point x,y
  text.content = string
  text.characterStyle =
    size:10
    fillColor: 'black'

midpt = (x1,x2) ->
  if x1 > x2
    x = (x2-x1)/2 + x1
  else
    x = (x1-x2)/2 + x2
  x

drawEvents = (events) ->
  setupArrowHeads()
  arrow_to_self = setupArrowToSelf()
  for e in events
    if e[2] == 'to_self'
      arrow_head_left.place [e[0]+3,e[1]+20]
      arrow = arrow_to_self.place [e[0]+20,e[1]+10]
      drawText e[0] + 50, e[1] + 15, e[3]
    else
      drawArrow e[0], e[4], e[1]
      drawText midpt(e[0], e[4]), e[1] - 10, e[3]

draw = (num_calls, num_events, calls, events) ->
  paperSetup num_calls, num_events
  drawCalls calls, $("canvas").attr('height')
  drawEvents events

window.draw = draw
