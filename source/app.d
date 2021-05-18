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
		logInfo("%s %s %s", req.query["id"], req.query["address"], req.query["value"]);
		return res.writeVoidBody();
	}
	else if (req.path == "/api/v1/execute") {
		if (req.json == null) {
			return res.writeBody("Invalid body", 400, "text/plain");
		}
		auto stackPointer = req.json["state"]["stackPointer"].get!int;
		const auto newLValue = requestHTTP(format("%s?id=%s&address=%d", readMemoryApi, req.json["id"].get!string, stackPointer)).bodyReader.readAllUTF8;
		const auto newHValue = requestHTTP(format("%s?id=%s&address=%d", readMemoryApi, req.json["id"].get!string, (stackPointer + 1) & 0xFFFF)).bodyReader.readAllUTF8;

		// Update memory at stack pointer with value of L
		requestHTTP(format("%s?id=%s&address=%s&value=%d", writeMemoryApi, req.json["id"].get!string, stackPointer, req.json["state"]["l"].get!int),
			(scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				req.writeJsonBody("");
			},
			(scope HTTPClientResponse res) {
				logInfo("WriteByte SP = L response: %s", res.bodyReader.readAllUTF8());
			}
		);
		// Update memory at stack pointer + 1 with value of H
		requestHTTP(format("%s?id=%s&address=%s&value=%d", writeMemoryApi, req.json["id"].get!string, (stackPointer + 1) & 0xFFFF, req.json["state"]["h"].get!int),
			(scope HTTPClientRequest req) {
				req.method = HTTPMethod.POST;
				req.writeJsonBody("");
			},
			(scope HTTPClientResponse res) {
				logInfo("WriteByte SP+1 = H response: %s", res.bodyReader.readAllUTF8());
			}
		);

		req.json["state"]["l"] = to!int(newLValue);
		req.json["state"]["h"] = to!int(newHValue);
		req.json["state"]["cycles"] = req.json["state"]["cycles"].get!int + 18;

		res.statusCode = HTTPStatus.OK;
		return res.writeBody(req.json.serializeToJsonString(), HTTPStatus.OK, "application/json");
	}		
	else {
		return res.writeBody("Not Found", HTTPStatus.NotFound, "text/plain");
	}
}
