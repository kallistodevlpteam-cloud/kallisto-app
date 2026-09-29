import { OdinService } from "./services/odin.js";
import { OllamaAdapter } from "./integrations/ollama.js";
import { createApp } from "./app.js";
import { loadEnvironment } from "./config/environment.js";
import { firebaseClientRepository } from "./repositories/firebase-client-repository.js";

try {
  const config = loadEnvironment();
  const repository = firebaseClientRepository(config);
  const odin = new OdinService(
    repository.store,
    new OllamaAdapter(process.env.OLLAMA_API_KEY ?? ""),
    {
      enabled:
        process.env.ODIN_CLOUD_PROCESSING_ALLOWED === "true" &&
        Boolean(process.env.OLLAMA_API_KEY),
      production: config.NODE_ENV === "production",
      dailyCalls: 64,
    },
  );
  const app = await createApp(
    repository,
    config.origins,
    repository.workflows,
    odin,
  );
  let ticking = false;
  const tick = async () => {
    if (ticking) return;
    ticking = true;
    try {
      await odin.pump();
    } catch {
      process.stderr.write("Odin worker unavailable; durable jobs retained.\n");
    } finally {
      ticking = false;
    }
  };
  const timer = setInterval(() => {
    void tick();
  }, 2000);
  timer.unref();
  app.addHook("onClose", async () => {
    clearInterval(timer);
  });
  void tick();
  const address = await app.listen({ host: config.HOST, port: config.PORT });
  process.stdout.write(`Kallisto backend listening at ${address}\n`);
} catch {
  process.stderr.write(
    "Kallisto backend could not start. Check server configuration and port availability.\n",
  );
  process.exitCode = 1;
}
