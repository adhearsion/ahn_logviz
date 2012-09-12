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

function arrow_to_self(context, x, y)
{
  context.beginPath();
  context.moveTo(x,y);
  context.lineTo(x+50, y);
  context.lineTo(x+50, y+20);
  draw_arrow(context, x+50, y+20, x, y+20);
  context.stroke();
}

function draw_arrow(context, fromx, fromy, tox, toy){
  var headlen = 10;   // length of head in pixels
  var angle = Math.atan2(toy-fromy,tox-fromx);
  context.moveTo(fromx, fromy);
  context.lineTo(tox, toy);
  context.lineTo(tox-headlen*Math.cos(angle-Math.PI/6),toy-headlen*Math.sin(angle-Math.PI/6));
  context.moveTo(tox, toy);
  context.lineTo(tox-headlen*Math.cos(angle+Math.PI/6),toy-headlen*Math.sin(angle+Math.PI/6));
}

function findTextX(midpt, string, context)
{
  var x = midpt - (context.measureText(string).width / 2);
  return x;
}

function drawEventText(from, to, y, evnt, context)
{
  if(to > from)
  {
    var midpt = from + (Math.abs(to - from) / 2);
    context.fillText(evnt, findTextX(midpt, evnt, context), y);
  }
  else
  {
    var midpt = to + (Math.abs(from - to) / 2);
    context.fillText(evnt, findTextX(midpt, evnt, context), y);
  }
}

function draw_chart(events, call_names)
{
  var canvas = document.getElementById('drawingCanvas');
  canvas.height = (events.length * 60 + 150).toString();
  canvas.width = (call_names.length * 160 + 50).toString();
  var context = canvas.getContext("2d");
  var call_array = create_call_array(call_names);
  var current_y = 100;
  context.fillStyle = "#55FFFF";
  context.strokeStyle = "#000000";
  for(i=0; i < events.length; i++)
  {
    events[i] = eval("(" + events[i] + ")")
  }
  for(i=0; i < call_array.length; i++)
  {
    context.font = "14px Arial"
    context.fillStyle = "#55FFFF"
    context.fillRect(i*160, 0, 150, 50);
    context.fillRect(i*160, parseInt(canvas.height) - 50, 150, 50);
    context.fillStyle = "#000000";
    context.fillText(call_array[i][0][1], i*160 + findTextX(75, call_array[i][0][1], context), 30);
    context.fillText(call_array[i][0][1], i*160 + findTextX(75, call_array[i][0][1], context), parseInt(canvas.height) - 20);
    context.beginPath();
    context.moveTo(i*160 + 75, 50);
    context.lineTo(i*160 + 75, parseInt(canvas.height) - 50);
    context.stroke();
  }
  for(i=0; i < events.length; i++)
  {
    var from = 0;
    var to = 0;
    for(j=0; j < call_array.length; j++)
    {
      if(events[i].to.valueOf() == call_array[j][0][0].valueOf())
      {
        to = call_array[j][1];
      }
      if(events[i].from.valueOf() == call_array[j][0][0].valueOf())
      {
        from = call_array[j][1];
      }
    }
    if(to == from)
    {
      arrow_to_self(context, from, current_y);
      context.fillStyle = "#000000";
      context.fillText(events[i].event, to + 55, current_y + 15);
      current_y += 70;
    }
    else
    {
      context.beginPath();
      draw_arrow(context, from, current_y, to, current_y);
      context.stroke();
      context.fillStyle = "#000000";
      drawEventText(from, to, current_y - 16, events[i].event, context);
      current_y += 50;
    }
  }
}
