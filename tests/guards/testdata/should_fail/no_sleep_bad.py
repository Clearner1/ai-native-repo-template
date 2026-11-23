# testdata/should_fail/no_sleep_bad.py
# This file MUST trigger guard_no_sleep.sh (RED proof).

import time
import asyncio


def test_user_creation_eventually_completes():
    """Bad: wall-clock sleep instead of a deterministic latch."""
    create_user("alice")
    time.sleep(2)          # ← guard must flag this line
    assert get_user("alice") is not None


async def test_notification_sent_async():
    """Bad: asyncio.sleep instead of an awaitable event."""
    send_notification("alice", "Welcome")
    await asyncio.sleep(0.5)  # ← guard must flag this line
    assert notification_delivered("alice")


def create_user(name): pass
def get_user(name): return object()
def send_notification(to, msg): pass
def notification_delivered(name): return True
