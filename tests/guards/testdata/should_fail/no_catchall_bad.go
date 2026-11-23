// testdata/should_fail/no_catchall_bad.go
// This file MUST trigger guard_no_catchall.sh (RED proof).

package testdata

import "fmt"

type OrderStatus int

const (
	Pending OrderStatus = iota
	Shipped
	Delivered
)

func describeStatus(s OrderStatus) string {
	switch s {
	case Pending:
		return "pending"
	case Shipped:
		return "shipped"
	default: // ← guard must flag this — silent swallow of unknown variants
		return "unknown"
	}
}

func handleEvent(kind string) {
	switch kind {
	case "created":
		fmt.Println("created")
	case "deleted":
		fmt.Println("deleted")
	default: // ← guard must flag this — Delivered would be silently dropped
		// ignore unknown events
		return
	}
}
