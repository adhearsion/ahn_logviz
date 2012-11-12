function showFlash(message) {
  $("#flash").html(message);
  $("#flash").css("padding", "1px");
  $("#flash").slideDown(400);
}

function hideFlash() {
  $("#flash").css("display", "hidden");
  $("#flash").html("");
}