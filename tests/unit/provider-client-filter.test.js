import { describe, expect, it } from "vitest";
import { parseProviderSelection } from "../../src/app/api/providers/client/route.js";
import { normalizeStoredProviderSelection } from "../../src/app/(dashboard)/dashboard/usage/components/ProviderLimits/utils.js";

describe("quota provider selection", () => {
  it("accepts multiple providers and the legacy single-provider query", () => {
    expect([...parseProviderSelection(new URLSearchParams("providers=codex,claude"))]).toEqual(["codex", "claude"]);
    expect([...parseProviderSelection(new URLSearchParams("provider=kiro"))]).toEqual(["kiro"]);
    expect(parseProviderSelection(new URLSearchParams("provider=all"))).toBeNull();
  });

  it("removes unavailable saved providers and collapses full selection to all", () => {
    expect(normalizeStoredProviderSelection(["codex", "removed"], ["codex", "claude"])).toEqual(["codex"]);
    expect(normalizeStoredProviderSelection(["codex", "claude"], ["codex", "claude"])).toBeNull();
    expect(normalizeStoredProviderSelection(["removed"], ["codex", "claude"])).toBeNull();
  });
});
