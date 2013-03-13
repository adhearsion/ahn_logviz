var colors = ['#AAF', '#AFA'];

function setup(num_calls, num_events) {
  $("canvas").width(num_calls * 200);
  $("canvas").height(num_events * 50);
  for(var i=0; i < num_calls; i++) {
    $("canvas").drawRect({
      layer: true
      x: i*200, y: 0,
      width: 200, height: $("canvas").height,
      fillStyle: colors[i]
    });
  }
}

function draw_calls(calls) {
  for(var i=0; i < calls.length; i++) {
    $("canvas").drawRect({
      x: (i*200 + 25), y: calls[i][1],
      width: 75, height: 25,
      fillStyle: "#AAA"
    });
    $("canvas").drawLine({
      x1: (i*100 + 50), y1: (calls[i][1] + 25),
      x2: (i*100 + 50), y2: $("canvas").height,
      strokeStyle: "#000", strokeWidth: 1
    });
    $("canvas").drawText({
      x: (i*100 + 50), y: (calls[i][1] + 12),
      fromCenter: true, font: "11px Arial",
      fillStyle: "#000", text: calls[i][0],
    });
  }
}

function draw_events(events) {
  for(var i=0; i < events.length; i++) {
    if(events[i][2].valueOf() == "to_self".valueOf()) {
      arrow_to_self(events[i][0], events[i][1]);
      draw_text(events[i][0] + 25, events[i][1] + 3, events[i][3], false)
    } else {
      var midpt = events[i][0] + ((events[i][4] - events[i][0])/2);
      draw_arrow(events[i][0], events[i][1], events[i][4], events[i][1]);
      draw_text(midpt, events[i][1] - 15, events[i][3], true)
    }
  }
}

function draw_text(x,y,text,from_center) {
  $("canvas").drawText({
    x: x, y: y,
    fromCenter: from_center, font: "11px Arial",
    fillStyle: "#000", text: text,
    maxWidth: 50
  });
}

function arrow_to_self(x,y) {
  $("canvas").drawLine({
    strokeStyle: "#000",
    strokeWidth: 1,
    rounded: true,
    x1: x, y1: y,
    x2: x+20, y2: y,
    x3: x+20, y3: y+10
  });
  draw_arrow(x+20, y+10, x, y+10);
}

function draw_arrow(from_x, from_y, to_x, to_y) {
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

function draw(num_calls, num_events, calls, events) {
  setup(num_calls, num_events);
  draw_calls(calls);
  draw_events(events);
  $("canvas").drawLayers();
}