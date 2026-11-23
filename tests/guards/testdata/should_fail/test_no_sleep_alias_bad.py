# testdata/should_fail/test_no_sleep_alias_bad.py
# This file MUST trigger guard_no_sleep.sh (RED proof) for alias import of sleep.

from time import sleep  # ← guard must flag this import line


def test_something_eventually_completes():
    """Bad: imported sleep used without qualification."""
    trigger_work()
    sleep(2)
    assert work_done()


def trigger_work(): pass
def work_done(): return True
