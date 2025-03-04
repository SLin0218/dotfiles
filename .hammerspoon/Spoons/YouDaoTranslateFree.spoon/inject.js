delByClass = function (className) {
  const nodes = document.getElementsByClassName(className);
  for (let i = 0; i < nodes.length; i++) {
    nodes[i].parentNode.removeChild(nodes[i]);
  }
};
classCss = function (className, css) {
  const nodes = document.getElementsByClassName(className);
  for (let i = 0; i < nodes.length; i++) {
    for (let b = 0; b < css.length; b++) {
      nodes[i].style[css[b][0]] = css[b][1];
    }
  }
};
const fanyiHeight =
  document.getElementsByClassName("fanyi")[0].offsetHeight + 72;
delByClass("fanyi__nav");
delByClass("inside__products");
delByClass("fanyi__footer");
delByClass("side__nav");
classCss("fanyi__operations", [["margin", "10px"]]);
classCss("fanyi", [
  ["margin", "10px 0 0 0"],
  ["height", fanyiHeight + "px"],
]);
classCss("fanyi__input", [["margin", "0 10px"]]);

var inputValue = function (st) {
  const inputElement = document.getElementById("inputOriginal");
  inputElement.focus();
  // if (inputElement.value == st) {
  //   return;
  // }
  // inputElement.value = st;
  // const inputEvent = document.createEvent("HTMLEvents");
  // inputEvent.initEvent("input", true, true);
  // inputElement.dispatchEvent(inputEvent);
};
