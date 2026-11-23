# testdata/should_pass/no_sleep_ok.py
# This file MUST NOT trigger guard_no_sleep.sh (GREEN proof).

import threading


def test_user_creation_with_latch():
    """Good: deterministic latch — no wall-clock sleep."""
    done = threading.Event()

    def on_created(user):
        done.set()

    create_user("alice", on_created=on_created)
    assert done.wait(timeout=5), "user creation timed out"
    assert get_user("alice") is not None


def test_pure_synchronous():
    """Good: synchronous call, no waiting needed."""
    result = compute_sum(1, 2)
    assert result == 3


def create_user(name, on_created=None):
    if on_created:
        on_created({"name": name})


def get_user(name):
    return {"name": name}


def compute_sum(a, b):
    return a + b
