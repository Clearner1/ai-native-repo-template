# testdata/should_fail/no_mirror_bad.py
# This file MUST trigger guard_no_mirror_assert.sh (RED proof).

import unittest


class UserTest(unittest.TestCase):

    def test_user_repr_bad(self):
        """Bad: asserting the string dump of an object instead of its properties."""
        user = {"id": 42, "name": "Alice", "role": "admin"}
        # guard must flag this — assertEqual(str(...), ...)
        self.assertEqual(str(user), "{'id': 42, 'name': 'Alice', 'role': 'admin'}")

    def test_order_total_bad(self):
        """Bad: comparing toString output instead of the numeric value."""
        order = {"total": 99.5, "currency": "USD"}
        expected = str(order)   # mirrors the internal repr
        # guard must flag this
        self.assertEqual(str(order), expected)
