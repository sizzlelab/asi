http = new XMLHttpRequest();

function test(token, base) {
    var url = document.getElementById('url').value;
    var method = document.getElementById('method').value;
    var params = "authenticity_token=" + token + "&" + document.getElementById('params').value;

    http.open(method, url, true);

    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.setRequestHeader("Accept", "application/json, image/*");
    http.setRequestHeader("Content-length", params.length);
    http.setRequestHeader("Connection", "close");

    http.onreadystatechange = useHttpResponse;
    http.send(params);
}

function useHttpResponse() {
    if (http.readyState == 4) {
        var resp = document.createElement("div");
        resp.className = "response";
        var code = document.createElement("strong");
        code.appendChild(document.createTextNode("Code: "));
        resp.appendChild(code);
        resp.appendChild(document.createTextNode(http.status));
        resp.appendChild(document.createElement("br"));
        var body = document.createElement("strong");
        body.appendChild(document.createTextNode("Body: "));
        resp.appendChild(body);
        resp.appendChild(document.createTextNode(http.responseText));
        document.getElementById('responses').insertBefore(resp, document.getElementById('responses').firstChild);
    }
}
