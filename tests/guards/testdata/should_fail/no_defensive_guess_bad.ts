// testdata/should_fail/no_defensive_guess_bad.ts
// This file MUST trigger guard_no_defensive_guess.sh (RED proof).

interface Payload {
  userId?: string;
  user_id?: string;
  id?: string;
}

function getUserId(payload: Payload): string {
  // Bad: speculative multi-fallback — binds to three different field names
  // instead of pinning to a canonical contract.
  return payload.userId ?? payload.user_id ?? payload.id ?? "";  // ← guard must flag
}

function getDisplayName(data: Record<string, string>): string {
  // Bad: same problem with bracket access
  return data["displayName"] ?? data["display_name"] ?? data["name"] ?? "";  // ← guard must flag
}
