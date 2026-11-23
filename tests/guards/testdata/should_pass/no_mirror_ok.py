# testdata/should_pass/no_mirror_ok.py
# This file MUST NOT trigger guard_no_mirror_assert.sh (GREEN proof).

import unittest


class UserTest(unittest.TestCase):

    def test_user_properties(self):
        """Good: asserts domain properties, not string dumps."""
        user = {"id": 42, "name": "Alice", "role": "admin"}
        self.assertEqual(user["id"], 42)
        self.assertEqual(user["name"], "Alice")
        self.assertEqual(user["role"], "admin")

    def test_order_total(self):
        """Good: asserts the numeric value directly."""
        order = {"total": 99.5, "currency": "USD"}
        self.assertAlmostEqual(order["total"], 99.5)
        self.assertEqual(order["currency"], "USD")
