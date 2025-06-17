Here's a script using chrome.ahk that will open a headless Chrome instance and make REST API calls:

```autohotkey
#NoEnv
#SingleInstance Force
#Include chrome.ahk

; Initialize headless Chrome instance
ChromeInst := new Chrome("", "--headless --disable-gpu --no-sandbox --disable-web-security")

; Wait for Chrome to start
Sleep, 2000

; Create a new page
Page := ChromeInst.GetPage()

; Function to make REST API calls
MakeRestCall(Page, Method, URL, Headers := "", Body := "") {
    ; Construct JavaScript code to make the API call
    JSCode := "
    (
    fetch('" . URL . "', {
        method: '" . Method . "',
        headers: " . (Headers ? Headers : "{}") . ",
        " . (Body ? "body: '" . Body . "'," : "") . "
    })
    .then(response => response.text())
    .then(data => {
        document.body.innerHTML = data;
        return data;
    })
    .catch(error => {
        document.body.innerHTML = 'Error: ' + error;
        return 'Error: ' + error;
    });
    )"
    
    ; Execute the JavaScript
    Page.Evaluate(JSCode)
    
    ; Wait for response
    Sleep, 2000
    
    ; Get the response from the page body
    Result := Page.Evaluate("document.body.innerHTML").value
    return Result
}

; Example usage - GET request
GetResponse := MakeRestCall(Page, "GET", "https://jsonplaceholder.typicode.com/posts/1")
MsgBox, GET Response: %GetResponse%

; Example usage - POST request with JSON data
PostHeaders := "{'Content-Type': 'application/json'}"
PostBody := "{\"title\": \"Test Post\", \"body\": \"This is a test\", \"userId\": 1}"
PostResponse := MakeRestCall(Page, "POST", "https://jsonplaceholder.typicode.com/posts", PostHeaders, PostBody)
MsgBox, POST Response: %PostResponse%

; Example usage - PUT request
PutHeaders := "{'Content-Type': 'application/json'}"
PutBody := "{\"id\": 1, \"title\": \"Updated Post\", \"body\": \"Updated content\", \"userId\": 1}"
PutResponse := MakeRestCall(Page, "PUT", "https://jsonplaceholder.typicode.com/posts/1", PutHeaders, PutBody)
MsgBox, PUT Response: %PutResponse%

; Example usage - DELETE request
DeleteResponse := MakeRestCall(Page, "DELETE", "https://jsonplaceholder.typicode.com/posts/1")
MsgBox, DELETE Response: %DeleteResponse%

; Close Chrome when done
ChromeInst.Kill()
ExitApp
```

Key features of this script:

**Headless Setup**: Chrome launches with `--headless`, `--disable-gpu`, `--no-sandbox`, and `--disable-web-security` flags to run invisibly and allow cross-origin requests.

**REST Methods**: The `MakeRestCall` function supports GET, POST, PUT, DELETE, and other HTTP methods.

**Headers & Body**: You can pass custom headers and request body data for POST/PUT requests.

**Response Handling**: The function returns the response text from the API calls.

**Error Handling**: Basic error handling is included in the JavaScript fetch call.

You can customize this further by:
- Adding authentication headers (Bearer tokens, API keys, etc.)
- Implementing more sophisticated error handling
- Adding request timeouts
- Storing responses to files instead of showing message boxes
- Creating a loop to make multiple API calls

The script runs completely in the background without any visible browser windows, making it perfect for automated API testing or data collection tasks.
