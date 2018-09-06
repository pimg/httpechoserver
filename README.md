# Simple commandline echo server
A simple commandline HTTP echo server written in Lua.
It is based on the example and libraries of https://github.com/daurnimator/lua-http

## Installation & running

Since the script is written in Lua a Lua runtime needs to be installed on your system.
The echo server was developed and tested against Lua 5.1.2.

For installation:
clone this repository

```bash
$ cd luahttpserver
$ chmod +x server_hello.lua
$ ./lua_server.lua  
```

To start the server on a specified port:

```bash
$ ./lua_server.lua 1234
```

To stop the server simply press Ctr-C

```bash
^C
Received interrupt, shutting down server
```

## Examples
The server simply echo's back the request it receives, and can therefore be used during development for checking requests. The echo server is in no means intended to run in production.

request:

```bash
$ curl localhost:1234/test?foo=bar -H 'version: v1' -d '{"test":"value"}'
```

response:
```bash
$ {
	"path": "\/test",
	"method": "POST",
	"body": "{\"test\":\"value\"}}",
	"scheme": "http",
	"query_params": {
		"foo": "bar"
	},
	"http_version": 1.1,
	"headers": {
		"Host": "localhost:1234",
		"content-type": "application\/x-www-form-urlencoded",
		"version": "v1",
		"accept": "*\/*",
		"user-agent": "curl\/7.47.0",
		"content-length": "17"
	}
}
```

console logging:
```bash
[06/Sep/2018:09:18:20 +0200] "POST /test?foo=bar HTTP/1.1"  "-" "curl/7.47.0" [{"test":"value"}}]
```
