delById = function (id) {
  const node = document.getElementById(id);
  node.parentNode.removeChild(node);
};
delByClass = function (className) {
  const nodes = document.getElementsByClassName(className);
  for (let i = 0; i < nodes.length; i++) {
    nodes[i].parentNode.removeChild(nodes[i]);
  }
};
preInput = "";
inputValue = function (st) {
  $(".textinput").trigger("focus");
  if (st === preInput.toLowerCase()) {
    return;
  }
  preInput = st;
  $(".textinput").val(st).trigger("input");
  var interval = setInterval(() => {
    if ($(".textpanel-source-suggest").css("display") === "block") {
      $(".textpanel-source-suggest").hide();
      clearInterval(interval);
    }
  }, 500);
};
delByClass("header");
delByClass("textpanel-banner");
delByClass("layout-float");
delByClass("rightLayer");
delByClass("dict-banner");
delByClass("language");
$(".layout-container").css("margin", "0").css("padding", "40px");
