import { spawn } from "node:child_process";
import net from "node:net";

const port = Number(process.env.PORT || 5000);
const host = process.env.HOST || "127.0.0.1";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function checkExistingBackend() {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 1500);

  try {
    const response = await fetch(`http://localhost:${port}/health`, {
      signal: controller.signal,
    });

    if (!response.ok) {
      return false;
    }

    const body = await response.json().catch(() => ({}));
    return body && typeof body === "object" && "status" in body;
  } catch {
    return false;
  } finally {
    clearTimeout(timeout);
  }
}

function checkPortAvailability() {
  return new Promise((resolve) => {
    const server = net.createServer();

    server.once("error", (error) => {
      if (error && error.code === "EADDRINUSE") {
        resolve(false);
        return;
      }
      resolve(false);
    });

    server.once("listening", () => {
      server.close(() => resolve(true));
    });

    server.listen(port, host);
  });
}

async function main() {
  const runningBackend = await checkExistingBackend();
  if (runningBackend) {
    console.log(
      `Backend already running at http://localhost:${port}. Reusing existing instance.`,
    );
    process.exit(0);
  }

  const isAvailable = await checkPortAvailability();
  if (!isAvailable) {
    console.error(
      `Port ${port} is already in use by another process. Stop it or change PORT before running backend.`,
    );
    process.exit(1);
  }

  await sleep(100);

  const child = spawn(process.execPath, ["--watch", "src/index.js"], {
    stdio: "inherit",
    env: process.env,
  });

  const forwardSignal = (signal) => {
    if (!child.killed) {
      child.kill(signal);
    }
  };

  process.on("SIGINT", () => forwardSignal("SIGINT"));
  process.on("SIGTERM", () => forwardSignal("SIGTERM"));

  child.on("exit", (code) => {
    process.exit(code ?? 0);
  });
}

main().catch((error) => {
  console.error("Failed to start backend dev runner:", error);
  process.exit(1);
});
