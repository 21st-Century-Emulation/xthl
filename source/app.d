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

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
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
		auto stackPointer = req.json["state"]["stackPointer"];
		const auto readAddress = format("%s?address=%d", readMemoryApi, stackPointer);
		const auto stackValueRequest = requestHTTP(readAddress).bodyReader.readAllUTF8;

		// Update memory at stack pointer with value of L
		const auto writeAddress = format("%s?address=%s&value=%s", writeMemoryApi, stackPointer, req.json["state"]["l"]);
		requestHTTP(writeAddress,
			(scope req) {
				req.method = HTTPMethod.POST;
			}
		);

		req.json["state"]["l"] = to!int(stackValueRequest);
		req.json["state"]["cycles"] = to!int(req.json["state"]["cycles"]) + 18;

		res.statusCode = HTTPStatus.OK;
		return res.writeBody(req.json.serializeToJsonString(), HTTPStatus.OK, "application/json");
	}		
	else {
		return res.writeBody("Not Found", HTTPStatus.NotFound, "text/plain");
	}
}
