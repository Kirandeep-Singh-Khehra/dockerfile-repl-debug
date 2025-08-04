#!/bin/bash
#<!--
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

if [[ $# == 0 ]]; then
  echo "Usage: $0 <dockerfile>"
  exit 1
fi

DOCKERFILE="${1}"
if ! [[ -f "${DOCKERFILE}" ]]; then
  echo "err: no such dockerfile '${DOCKERFILE}'"
  exit 1
fi

get_free_port() {
  BASE_PORT=16998
  INCREMENT=1

  PORT=$BASE_PORT

  IS_FREE=$(busybox netstat -taln | grep $PORT)

  while [[ -n "$IS_FREE" ]]; do
      PORT=$[PORT+INCREMENT]
      IS_FREE=$(busybox netstat -taln | grep $PORT)
  done

  echo "${PORT}"
}

serv() {
  cp "${DOCKERFILE}" "${DOCKERFILE}.drp"

  HTTPD_CONF="
.drp:text/html
*.drp:${SCRIPT_PATH}
"
  PORT="$(get_free_port)"
  echo "Starting server ..."
  echo "Goto: http://localhost:${PORT}/${DOCKERFILE}.drp"
  busybox httpd -f -vv -p "${PORT}" -c <(echo "${HTTPD_CONF}") || echo "[-] Failed to start busybox server"
}

run_df() {
  COMMAND_TO_RUN=(
    "bash"
    "-c"
    "BUILDX_EXPERIMENTAL=1 docker buildx debug --invoke sh build -f ${DOCKERFILE}.drp ."
  )
  local HOST=$(ip route get 1.2.3.4 | awk '{print $7}')
  local PORT=$(get_free_port)
  echo "{ \"host\": \"${HOST}\", \"port\": \"${PORT}\"}"
  # ttyd --writable --once --port ${PORT} /bin/bash -c "${COMMAND_TO_RUN}" > /dev/null 2>&1 &
  ttyd --writable --once --port ${PORT} "${COMMAND_TO_RUN[@]}" &>/dev/null &
}


if [[ -z "${REQUEST_METHOD}" ]]; then
  serv
elif [[ "${REQUEST_METHOD}" == "GET" ]]; then
  echo "Content-Type: text/html"
  echo ""
  echo "[+] You want page" > /dev/stderr
  tail -n+2 | sed -n '/^<!DOCTYPE html>$/, $p'  "${SCRIPT_PATH}"
elif [[ "${REQUEST_METHOD}" == "POST" ]]; then
  echo ""
  echo "[+] You want to build" > /dev/stderr
  cat > "${DOCKERFILE}.drp"
  run_df
fi

exit 0

# -->
<!DOCTYPE html>
<html>
<head>
  <title>Dockerfile-REPL</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.39.1/ace.min.js" type="text/javascript" charset="utf-8"></script>
  <style>
  .dialog {
    border: 1px solid #ccc;
    padding: 20px;
    margin: 20px;
    background-color: #f9f9f9;
  }
  .hidden {
    display: none;
  }
  </style>
	<!-- <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous"> -->
</head>
<body>
  <div class="nav-bar">
    <button onclick="document.getElementById('load-dialog').classList.toggle('hidden');">Load</button>
    <button onclick="copy_to_clipboard_df()">Copy</button>
    <button onclick="clear_df()">Clear</button>
    <div id="load-dialog" class="dialog hidden">
      <textarea id="df-input" style="width: 100%; min-height: 100px;" placeholder="Paste your Dockerfile here"></textarea>
      <br/>
      <button onclick="load_df(document.getElementById('df-input').value)">Load File</button>
    </div>
  </div>

  <div class="sep-div">
    <hr/>
    <button class="btn-add" onclick="add_block(this.parentNode)">Add</button>
    <hr/>
  </div>
  <div class="sep-div">
    <button id="btn-run-complete" onclick="run_till_me(this)" style="position: absolute;top: 10px;right: 10px;">Run Complete file</button>
  </div>
  <script>
var editors = []
var id_count=0
const currentPath = window.location.pathname;

function add_block(clickedDiv) {
  // Create a new textarea element
  const textarea = createEditor()
  // textarea.classList.add('editor');
  textarea.id = "code_" + id_count ++

  // Create a new separator div
  const newSepDiv = document.createElement('div');
  newSepDiv.classList.add('sep-div');
  newSepDiv.innerHTML = `
    <button class="btn-rem" onclick="this.parentNode.previousElementSibling.outerHTML = '';
                    this.parentNode.outerHTML = ''">Remove</button>
    <button class="btn-int" onclick="run_till_me(this)">Interact</button>
    <br/>
    <hr/>
    <button class="btn-add" onclick="add_block(this.parentNode)">Add</button>
    <hr/>
  `;

  // Insert the textarea after the clicked div
  clickedDiv.parentNode.insertBefore(textarea, clickedDiv.nextSibling);

  // Insert the new separator div after the newly added textarea
  clickedDiv.parentNode.insertBefore(newSepDiv, textarea.nextSibling);
}

function run_till_me(clickedButton) {
  debug_in_terminal(get_df_till_me(clickedButton) + "\n\n#Command will fail to trigger interactive debug\nRUN exit 1")
}

function get_df_till_me(clickedButton) {
  // Start from the div containing the clicked button
  let currentSeparatorDiv = clickedButton.parentNode;
  const textAreasContent = []; // Array to hold the content

  // Start checking elements *before* the current separator div
  let previousElement = currentSeparatorDiv.previousElementSibling;

  // Loop backwards through all previous sibling elements
  while (previousElement) {
    // Check if the current previous sibling is a TEXTAREA
    // nodeName or tagName should be checked in uppercase
    if (previousElement.id.startsWith("code_")) {
      // If it is, add its value to the beginning of the array
      // to maintain the original top-to-bottom order
      textAreasContent.unshift(editors[previousElement.id.substring(5)].getValue())
    }
    // Move to the next previous sibling
    previousElement = previousElement.previousElementSibling;
  }

  // Log the collected content
  console.log("Content of textareas before this button:");
  console.log(textAreasContent);

  return textAreasContent.join("\n\n");

  // Optional: Log as a single string for easier viewing if needed
  // console.log(textAreasContent.join('\n---\n'));
}

function createEditor() {
  var editor = ace.edit()
  editor.container.style.height = "100px"
  editor.session.setMode("ace/mode/dockerfile");

  editor.setOptions({
      fontSize: 18,
      maxLines: Infinity
  });

  editors.push(editor)
  return editor.container
}

function getUrlParameter(name) {
  name = name.replace(/[\[\]]/g, '\\$&');
  const url = window.location.href;
  const regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');
  const results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function debug_in_terminal(dockerfile) {
    var xhr=new XMLHttpRequest();
    const sid = getUrlParameter('sid');
    xhr.open("POST", `${currentPath}`, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.send(dockerfile);

    xhr.onloadend = function() {
        console.log("Hi")
        if (xhr.status == 200){
            console.log(xhr.responseText)
            obj = JSON.parse(xhr.responseText)

            window.open(`http://${obj['host']}:${obj['port']}`, "_blank", "popup,left=224,top=126,width=800,height=450");
        }
    }
}

function clear_df() {
  var code_blocks = document.getElementsByClassName('btn-rem');
  for (let i = code_blocks.length - 1; i >= 0; i--) {
    code_blocks[i].parentNode.previousElementSibling.outerHTML = '';
    code_blocks[i].parentNode.outerHTML = '';
  }

  editors = []
}

function load_df(df_text) {
  clear_df()

  const lines = df_text.split('\n\n');
  blocks_index = 0
  for (block of lines) {
    var code_blocks = document.getElementsByClassName('btn-add');
    console.log(block);
    add_block(code_blocks[blocks_index].parentNode);
    editors[blocks_index].setValue(block, -1);
    blocks_index ++;
  }

  document.getElementById("df-input").value = "";
  document.getElementById('load-dialog').classList.add('hidden');
}

function copy_to_clipboard_df() {
  let text = get_df_till_me(document.getElementById('btn-run-complete'))
  navigator.clipboard.writeText(text)
  alert("Copied dockerfile to clipboard")
}

async function onload() {
  const modifiedPath = currentPath.endsWith('.drp') 
          ? currentPath.slice(0, -4) 
          : currentPath;
  const response = await fetch(modifiedPath);
  load_df(await response.text());
}

onload()
  </script>
</body>
</html>
