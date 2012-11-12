var currentEvent;
function create_call_array(call_names)
{
  var call_array = [];
  var current_x = 60;
  for(i=0; i < call_names.length; i++)
  {
    call_array[i] = [call_names[i], current_x];
    current_x += 127;
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
    layer: true,
    strokeStyle: "#000",
    strokeWidth: 1,
    rounded: true,
    x1: x, y1: y,
    x2: x+50, y2: y,
    x3: x+50, y3: y+15
  });
  drawArrow(x+50, y+15, x, y+15);
}

function drawArrow(from_x, from_y, to_x, to_y)
{
  var head = 10;
  var angle = Math.atan2(to_y-from_y, to_x-from_x);
  $("canvas").drawLine({
    layer: true,
    strokeStyle: "#000",
    strokeWidth: 1,
    x1: from_x, y1: from_y,
    x2: to_x, y2: to_y,
    x3: to_x-head*Math.cos(angle-Math.PI/6),
    y3: to_y-head*Math.sin(angle-Math.PI/6)
  }).drawLine({
    layer: true,
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
    c1: "#333",
    c2: "#aaa"
  });
  return linear;
}

function drawEntities(call_array) {
  var lower_y = parseInt(document.getElementById('drawingCanvas').height) - 25;
  for(i=0; i < call_array.length; i++)
  {
    $("canvas").drawRect({
      layer: true,
      fillStyle: createEntityGradient(i*105,0),
      x: i*127, y: 0,
      width: 120, height: 30,
      fromCenter: false,
      cornerRadius: 10
    }).drawRect({
      layer: true,
      fillStyle: createEntityGradient(i*105,lower_y),
      x: i*127, y: lower_y,
      width: 120, height: 30,
      fromCenter: false,
      cornerRadius: 10
    });
    $("canvas").drawText({
      layer: true,
      x: i*127 + 60, y: 15,
      fillStyle: "#FFF",
      font: "12px Arial",
      fromCenter: true,
      maxWidth: 100,
      text: call_array[i][0][1]
    }).drawText({
      layer: true,
      x: i*127+60, y: lower_y + 15,
      fillStyle: "#FFF",
      font: "12px Arial",
      fromCenter: true,
      maxWidth: 100,
      text: call_array[i][0][1]
    });
    $("canvas").drawLine({
      layer: true,
      x1: i*127+60, y1: 30,
      x2: i*127+60, y2: lower_y,
      strokeStyle: "#000",
      strokeWidth: 1
    });
  }
}

function drawEvents(call_array, events_array)
{
  var current_y = 60;
  for(i=0; i < events_array.length; i++)
  {
    currentEvent = i;
    var from = 0;
    var to = 0;
    for(j=0; j < call_array.length; j++)
    {
      if(events_array[i].message.to.valueOf() == call_array[j][0][0].valueOf())
      {
        to = call_array[j][1];
      }
      if(events_array[i].message.from.valueOf() == call_array[j][0][0].valueOf())
      {
        from = call_array[j][1];
      }
    }

    $("body").append("<div id='event_" + i.toString() + "' style='display: none; position: absolute;'></div>");
    $("#event_" + i.toString()).text(events_array[i].log).html();
    $("#event_" + i.toString()).addClass('ui-corner-all')
    $("#event_" + i.toString()).click(function() {
      $(this).hide(400);
    });
    $("#event_" + i.toString()).mouseover(function() {
      $(this).css({cursor: "pointer"});
    });
    $("#event_" + i.toString()).mouseout(function() {
      $(this).css({cursor: "default"});
    });

    if(to == from)
    {
      arrowToSelf(from, current_y);
      $("canvas").drawRect({
        layer: true,
        name: "event_rect_" + currentEvent.toString(),
        x: from + 55, y: current_y,
        fromCenter: false,
        fillStyle: "#7DE",
        width: $("canvas").measureText({ font: "11px Arial", text: events_array[i].message.event}).width,
        height: 11
      }).drawText({
        layer: true,
        x: from + 55, y: current_y,
        fromCenter: false,
        font: "11px Arial",
        fillStyle: "#000",
        text: events_array[i].message.event,
        name: "event_" + currentEvent.toString(),
        mouseover: function() {
          $(this).css({cursor: "pointer"});  
        },
        mouseout: function() {
          $(this).css({cursor: "default"});  
        },
        click: function(layer) {
          $("#" + layer.name).css("left", ($("canvas").offset().left + layer.x).toString() + "px");
          $("#" + layer.name).css("top", ($("canvas").offset().top + layer.y).toString() + "px");
          $("#" + layer.name).css("width", "500px");
          $("#" + layer.name).css("font", "10px Arial");
          $("#" + layer.name).css("background-color", "#FFFFFF");
          $("#" + layer.name).css("border", "1px solid black");
          $("#" + layer.name).show(400);
        }
      });
      current_y += 50;
    } else {
      drawArrow(from, current_y, to, current_y);
      if(to > from) {
        var midpt = from + (Math.abs(to - from) / 2);
      } else {
        var midpt = to + (Math.abs(to - from) / 2);
      }
      $("canvas").drawRect({
        layer: true,
        name: "event_rect_" + currentEvent.toString(),
        x: midpt, y: current_y - 15,
        fromCenter: true,
        fillStyle: "#7DE",
        width: $("canvas").measureText({ font: "11px Arial", text: events_array[i].message.event}).width,
        height: 11
      }).drawText({
        layer: true,
        x: midpt, y: current_y - 15,
        fromCenter: true,
        font: "11px Arial",
        fillStyle: "#000",
        text: events_array[i].message.event,
        name: "event_" + currentEvent.toString(),
        mouseover: function() {
          $(this).css({cursor: "pointer"});  
        },
        mouseout: function() {
          $(this).css({cursor: "default"});  
        },
        click: function(layer) {
          $("#" + layer.name).css("left", ($("canvas").offset().left + layer.x).toString() + "px");
          $("#" + layer.name).css("top", ($("canvas").offset().top + layer.y).toString() + "px");
          $("#" + layer.name).css("width", "500px");
          $("#" + layer.name).css("font", "10px Arial");
          $("#" + layer.name).css("background-color", "#FFFFFF");
          $("#" + layer.name).css("border", "1px solid black");
          $("#" + layer.name).show(400);
        }
      });
      current_y += 30;
    }
  }
}

function drawChart(events, call_names)
{
  call_array = create_call_array(call_names);
  events_array = create_events_array(events);
  var canvas = document.getElementById('drawingCanvas');
  canvas.height = (events.length * 40 + 150).toString();
  canvas.width = (call_names.length * 127 + 50).toString();
  $("#content").width(canvas.width);
  $("#contentBody").height(canvas.height);
  if($.browser.mozilla) {
    $("canvas").css("left", "20px")
  }
  drawEntities(call_array);
  drawEvents(call_array, events_array);
  $("canvas").drawLayers();
}