import std.process;
import vibe.vibe;
import vibe.data.serialization;
import vibe.data.json;
import vibe.http.client : requestHTTP;

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "0.0.0.0"];
	listenHTTP(settings, &execute);
	runApplication();
}

private void execute(HTTPServerRequest req, HTTPServerResponse res)
{
	auto readMemoryApi = environment.get("READ_MEMORY_API");
	auto writeMemoryApi = environment.get("WRITE_MEMORY_API");

	if (req.path == "/status") {
		return res.writeBody("Healthy", HTTPStatus.OK, "text/plain");
	}
	else if (req.path == "/api/v1/debug/readMemory") {
		return res.writeBody("17", HTTPStatus.OK, "text/plain");
	}
	else if (req.path == "/api/v1/debug/writeMemory") {
		res.statusCode = HTTPStatus.OK;
		return res.writeVoidBody();
	}
	else if (req.path == "/api/v1/execute") {
		if (req.json == null) {
			return res.writeBody("Invalid body", 400, "text/plain");
		}
		auto stackPointer = req.json["state"]["stackPointer"].get!int;
		const auto readAddress = format("%s?id=%s&address=%d", readMemoryApi, req.json["id"].get!string, stackPointer);
		logWarn(readAddress);
		const auto stackValueRequest = requestHTTP(readAddress).bodyReader.readAllUTF8;
		logWarn(stackValueRequest);

		// Update memory at stack pointer with value of L
		const auto writeAddress = format("%s?id=%s&address=%s&value=%s", writeMemoryApi, req.json["id"].get!string, stackPointer, req.json["state"]["l"].get!int);
		logWarn(writeAddress);
		requestHTTP(writeAddress,
			(scope req) {
				req.method = HTTPMethod.POST;
			}
		);

		req.json["state"]["l"] = to!int(stackValueRequest);
		req.json["state"]["cycles"] = req.json["state"]["cycles"].get!int + 18;

		res.statusCode = HTTPStatus.OK;
		return res.writeBody(req.json.serializeToJsonString(), HTTPStatus.OK, "application/json");
	}		
	else {
		return res.writeBody("Not Found", HTTPStatus.NotFound, "text/plain");
	}
}
