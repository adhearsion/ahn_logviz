function create_call_array(call_names)
{
  var call_array = [];
  var current_x = 75;
  for(i=0; i < call_names.length; i++)
  {
    call_array[i] = [call_names[i], current_x];
    current_x += 160;
  }
  return call_array;
}

function create_events_array(events)
{
  for(i=0; i < events.length; i++)
  {
    events[i] = eval("(" + events[i] + ")")
  }
  return events;
}

function arrowToSelf(x,y)
{
  $("canvas").drawLine({
    strokeStyle: "#000",
    strokeWidth: 1,
    rounded: true,
    x1: x, y1: y,
    x2: x+50, y2: y,
    x3: x+50, y3: y+20
  });
  drawArrow(x+50, y+20, x, y+20);
}

function drawArrow(from_x, from_y, to_x, to_y)
{
  var head = 10;
  var angle = Math.atan2(to_y-from_y, to_x-from_x);
  $("canvas").drawLine({
    strokeStyle: "#000",
    strokeWidth: 1,
    x1: from_x, y1: from_y,
    x2: to_x, y2: to_y,
    x3: to_x-head*Math.cos(angle-Math.PI/6),
    y3: to_y-head*Math.sin(angle-Math.PI/6)
  }).drawLine({
    x1: to_x, y1: to_y,
    x2: to_x-head*Math.cos(angle+Math.PI/6),
    y2: to_y-head*Math.sin(angle+Math.PI/6)
  });
}

function createEntityGradient(x,y)
{
  var linear = $("canvas").createGradient({
    x1: x, y1: y,
    x2: x, y2: y+50,
    c1: "#00ABEB",
    c2: "#FFF"
  });
  return linear;
}

function drawEntities(call_array) {
  var lower_y = parseInt(document.getElementById('drawingCanvas').height) - 50;
  for(i=0; i < call_array.length; i++)
  {
    $("canvas").drawRect({
      fillStyle: createEntityGradient(i*160,0),
      x: i*160, y: 0,
      width: 150, height: 50,
      fromCenter: false,
      cornerRadius: 10
    }).drawRect({
      fillStyle: createEntityGradient(i*160,lower_y),
      x: i*160, y: lower_y,
      width: 150, height: 50,
      fromCenter: false,
      cornerRadius: 10
    });
    $("canvas").drawText({
      x: i*160 + 75, y: 25,
      fillStyle: "#000",
      font: "18px Arial",
      fromCenter: true,
      maxWidth: 125,
      text: call_array[i][0][1]
    }).drawText({
      x: i*160 + 75, y: lower_y + 25,
      fillStyle: "#000",
      font: "18px Arial",
      fromCenter: true,
      maxWidth: 125,
      text: call_array[i][0][1]
    });
    $("canvas").drawLine({
      x1: i*160 + 75, y1: 50,
      x2: i*160 + 75, y2: lower_y,
      strokeStyle: "#000",
      strokeWidth: 1
    });
  }
}

function drawEvents(call_array, events_array)
{
  var current_y = 100;
  for(i=0; i < events_array.length; i++)
  {
    var from = 0;
    var to = 0;
    for(j=0; j < call_array.length; j++)
    {
      if(events_array[i].to.valueOf() == call_array[j][0][0].valueOf())
      {
        to = call_array[j][1];
      }
      if(events_array[i].from.valueOf() == call_array[j][0][0].valueOf())
      {
        from = call_array[j][1];
      }
    }

    if(to == from)
    {
      arrowToSelf(from, current_y);
      $("canvas").drawText({
        x: from + 55, y: current_y,
        fromCenter: false,
        font: "14px Arial",
        fillStyle: "#000",
        text: events_array[i].event
        //onclick: displayEventInfo(events_array[i])
      });
      current_y += 70;
    } else {
      drawArrow(from, current_y, to, current_y);
      var midpt = from + (Math.abs(to - from) / 2);
      $("canvas").drawText({
        x: midpt, y: current_y - 15,
        fromCenter: true,
        font: "14px Arial",
        fillStyle: "#000",
        text: events_array[i].event
        //onclick: displayEventInfo(events_array[i])
      });
      current_y += 50;
    }
  }
}

function drawChart(events, call_names)
{
  call_array = create_call_array(call_names);
  events_array = create_events_array(events);
  var canvas = document.getElementById('drawingCanvas');
  canvas.height = (events.length * 60 + 150).toString();
  canvas.width = (call_names.length * 160 + 50).toString();
  drawEntities(call_array);
  drawEvents(call_array, events_array);
}