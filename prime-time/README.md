Prime Time

Accept TCP Connection -> passed

Whenever receive a conforming request, send back a correct response and wait for another request

Whenever you receive a malformed request, send back a single malformed response, and disconnect the client.

Handle at least 5 Connection

The client have to send json

{"method":string, "prime":number}

method only contain isPrime and prime field must contain a valid number.

the server should response like this

Example Response

{"method":"isPrime","prime":bool}

Resources

JSON docs : https://www.json.org/json-en.html

An object is unordered a name/value pairs.

an object begins with left brace and end with right brace

Each name is followed by colon and the name is separated by comma

Example object JSON:

{
    "employee": {
        "name": "sonoo",
        "salary": 56000,
        "married": true
    }
}
