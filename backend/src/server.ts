import { createApp } from "./app.js";
import { loadEnvironment } from "./config/environment.js";
import { firebaseClientRepository } from "./repositories/firebase-client-repository.js";

try {
  const config = loadEnvironment();
  const repository = firebaseClientRepository(config);
  const app = await createApp(repository, config.origins, repository.workflows);
  const address = await app.listen({ host: config.HOST, port: config.PORT });
  process.stdout.write(`Kallisto backend listening at ${address}\n`);
} catch {
  process.stderr.write(
    "Kallisto backend could not start. Check server configuration and port availability.\n",
  );
  process.exitCode = 1;
}
