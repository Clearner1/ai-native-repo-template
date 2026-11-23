// testdata/should_fail/no_sleep_timer_bad_test.go
// This file MUST trigger guard_no_sleep.sh (RED proof) for <-time.After idiom.
package testdata

import (
	"testing"
	"time"
)

func TestEventuallyDelivered_Bad(t *testing.T) {
	// Bad: using timer channel as a sleep instead of a deterministic latch.
	triggerEvent()
	<-time.After(500 * time.Millisecond) // ← guard must flag this line
	if !eventDelivered() {
		t.Fatal("event not delivered")
	}
}

func triggerEvent()    {}
func eventDelivered() bool { return true }
