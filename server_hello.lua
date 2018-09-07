#!/usr/bin/env lua
--[[
A simple HTTP server
If a request is not a HEAD method, then reply with "Hello world!"
Usage: lua examples/server_hello.lua [<port>]
]]

local port = arg[1] or 0 -- 0 means pick one at random

local http_server = require "http.server"
local http_headers = require "http.headers"
local http_util = require "http.util"
local pretty = require "resty.prettycjson"
local cjson = require "cjson"
local signal = require("posix.signal")

local function createQueryParamTable (path)
	local query_tbl = {}

	local seperator = path:find("?")

	if not seperator then
		return path, {};
	end

	local query_str = path:sub(seperator+1)
	local path_str = path:sub(0, seperator - 1)

	for name, value in http_util.query_args(query_str) do
		query_tbl[name] = value
	end

	return path_str, query_tbl
end

local function createHeaderTable(headers, http_version)
	local headerTbl = {}

	for name, value, never_index in headers:each() do

		if http_version < 2 then

			if name == ":authority" then
				headerTbl["Host"] = value
			end

			if name:sub(0,1) ~= ":" then
				headerTbl[name] = value
			end

		else
			headerTbl[name] = value
		end

	end

	return headerTbl
end

local function reply(myserver, stream) -- luacheck: ignore 212
	-- Read in headers
	local req_headers = assert(stream:get_headers())
	local req_method = req_headers:get ":method"
	local req_scheme = req_headers:get ":scheme"
	local req_body = assert(stream:get_body_as_string(1000))
	local req_path = req_headers:get(":path") or ""
	local http_version = stream.connection.version
	local path_str, query_tbl = createQueryParamTable(req_path)
	local header_tbl = createHeaderTable(req_headers, http_version)

	-- Log request to stdout
	assert(io.stdout:write(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s" [%s]\n',
		os.date("%d/%b/%Y:%H:%M:%S %z"),
		req_method or "",
		req_path,
		stream.connection.version,
		req_headers:get("referer") or "-",
		req_headers:get("user-agent") or "-",
		req_body or ""
	)))

	-- Build resonse body
	local res_body = {
		method = req_method,
		path = path_str,
		scheme = req_scheme,
		http_version = http_version,
		headers = header_tbl,
		query_params = query_tbl,
		body = req_body
	}

	-- Build response headers
	local res_headers = http_headers.new()
	res_headers:append(":status", "200")
	res_headers:append("content-type", "text/plain")
	-- Send headers to client; end the stream immediately if this was a HEAD request
	assert(stream:write_headers(res_headers, req_method == "HEAD"))
	if req_method ~= "HEAD" then
		-- Send body, ending the stream
		assert(stream:write_chunk(pretty(res_body), true))
	end
end

local myserver = assert(http_server.listen {
	host = "localhost";
	port = port;
	onstream = reply;
	onerror = function(myserver, context, op, err, errno) -- luacheck: ignore 212
		local msg = op .. " on " .. tostring(context) .. " failed"
		if err then
			msg = msg .. ": " .. tostring(err)
		end
		assert(io.stderr:write(msg, "\n"))
	end;
})

-- Manually call :listen() so that we are bound before calling :localname()
assert(myserver:listen())
do
	local bound_port = select(3, myserver:localname())
	assert(io.stderr:write(string.format("Now listening on port %d\n", bound_port)))
end

-- catching interrupts so a clean shutdown can be performed
signal.signal(signal.SIGINT, function(signum)
  io.write("\n")

	print("Received interrupt, shutting down server")
	myserver:close()
  os.exit(128 + signum)
end)

--Running the server on the foreground
assert(myserver:loop())
