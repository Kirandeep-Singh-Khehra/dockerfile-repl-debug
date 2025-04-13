var editors = []
var id_count=0

// function fix_cors() {
//     var xhr=new XMLHttpRequest();

//     xhr.open("GET", `/cgi-bin/fix-cors.cgi`, true);
//     xhr.setRequestHeader("Content-Type", "application/json");
//     xhr.send();
//     console.log("CORS Fixed")
// }

// fix_cors()

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

function debug_in_terminal(dockerfile) {
    var xhr=new XMLHttpRequest();

    xhr.open("POST", `/cgi-bin/run-df.cgi`, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.send(dockerfile);

    xhr.onloadend = function() {
        if (xhr.status == 200 && xhr.getResponseHeader('Content-type') == "application/json"){
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
  // const df_text = document.getElementById("df-input").value;
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
