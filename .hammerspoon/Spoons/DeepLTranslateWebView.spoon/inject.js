window.delById = function (id) {
    const node = document.getElementById(id);
    node.parentNode.removeChild(node);
};
window.delByClass = function (className) {
    const nodes = document.getElementsByClassName(className);
    for (let i = 0; i < nodes.length; i++) {
        nodes[i].parentNode.removeChild(nodes[i]);
    }
};
window.preInput = "";
window.inputValue = function (st) {
    if (st === preInput.toLowerCase()) {
        $($(".lmt__textarea")[0]).trigger("focus").trigger("input");
        return;
    }
    window.preInput = st;
    $($(".lmt__textarea")[0]).val(st).trigger("focus").trigger("input");
};
window.delByClass("dl_header");
window.delById("lmt_pro_ad_container_1");
window.delById("lmt_pro_ad_container_2");
window.delById("lmt_quotes_article");
window.delByClass("dl_footer");
