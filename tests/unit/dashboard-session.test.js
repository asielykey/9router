import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const state = vi.hoisted(() => ({
  dataDir: "",
}));

vi.mock("@/lib/dataDir", () => ({
  get DATA_DIR() {
    return state.dataDir;
  },
}));

vi.mock("@/lib/localDb", () => ({
  getSettings: vi.fn(async () => ({})),
}));

beforeAll(() => {
  state.dataDir = fs.mkdtempSync(path.join(os.tmpdir(), "9router-dashboard-session-"));
});

afterAll(() => {
  fs.rmSync(state.dataDir, { recursive: true, force: true });
});

describe("dashboard auth session", () => {
  it("issues a persistent cookie and JWT with the same 30-day lifetime", async () => {
    const {
      createDashboardAuthToken,
      DASHBOARD_SESSION_MAX_AGE_SECONDS,
      setDashboardAuthCookie,
    } = await import("../../src/lib/auth/dashboardSession.js");
    const cookieStore = { set: vi.fn() };
    const before = Date.now();

    await setDashboardAuthCookie(cookieStore, new Request("http://localhost:20127/login"));

    expect(cookieStore.set).toHaveBeenCalledTimes(1);
    const [name, token, options] = cookieStore.set.mock.calls[0];
    expect(name).toBe("auth_token");
    expect(options).toMatchObject({
      httpOnly: true,
      secure: false,
      sameSite: "lax",
      path: "/",
      maxAge: DASHBOARD_SESSION_MAX_AGE_SECONDS,
    });
    expect(options.expires.getTime()).toBeGreaterThanOrEqual(
      before + DASHBOARD_SESSION_MAX_AGE_SECONDS * 1000
    );

    const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString("utf8"));
    expect(payload.exp - payload.iat).toBe(DASHBOARD_SESSION_MAX_AGE_SECONDS);

    const directToken = await createDashboardAuthToken();
    const directPayload = JSON.parse(
      Buffer.from(directToken.split(".")[1], "base64url").toString("utf8")
    );
    expect(directPayload.exp - directPayload.iat).toBe(DASHBOARD_SESSION_MAX_AGE_SECONDS);
  });

  it("keeps Secure disabled on HTTP loopback and enables it behind HTTPS", async () => {
    const { setDashboardAuthCookie } = await import("../../src/lib/auth/dashboardSession.js");
    const httpStore = { set: vi.fn() };
    const httpsStore = { set: vi.fn() };

    await setDashboardAuthCookie(httpStore, new Request("http://localhost:20127/login"));
    await setDashboardAuthCookie(
      httpsStore,
      new Request("http://localhost:20127/login", {
        headers: { "x-forwarded-proto": "https" },
      })
    );

    expect(httpStore.set.mock.calls[0][2].secure).toBe(false);
    expect(httpsStore.set.mock.calls[0][2].secure).toBe(true);
  });
});
