// testdata/should_fail/no_catchall_singleline_bad_test.go
// This file MUST trigger guard_no_catchall.sh (RED proof) for single-line default: return.
package testdata

// ProcessEvent handles event types — bad: single-line default swallows unknown events silently.
func ProcessEvent(eventType string) string {
	switch eventType {
	case "login":
		return "user logged in"
	case "logout":
		return "user logged out"
	default: return "" // ← guard must flag this — single-line silent catchall
	}
}

// ProcessStatus — bad: single-line default: break
func ProcessStatus(code int) {
	switch code {
	case 200:
		println("ok")
	default: break // ← guard must flag this
	}
}
