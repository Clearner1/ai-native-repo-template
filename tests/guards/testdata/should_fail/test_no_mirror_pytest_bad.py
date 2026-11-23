# testdata/should_fail/test_no_mirror_pytest_bad.py
# This file MUST trigger guard_no_mirror_assert.sh (RED proof) for Pytest-style patterns.

class Order:
    def __init__(self, total, currency):
        self.total = total
        self.currency = currency
    def __str__(self):
        return f"Order(total={self.total}, currency={self.currency})"


def test_order_str_bad():
    """Bad: asserting str() dump of an object (Pytest style, not unittest)."""
    order = Order(99.5, "USD")
    # guard must flag this — assert str(obj) == ...
    assert str(order) == "Order(total=99.5, currency=USD)"


def test_order_fstring_bad():
    """Bad: asserting f-string interpolation of an object."""
    order = Order(99.5, "USD")
    # guard must flag this — assert f"{obj}" mirrors internal repr
    assert f"{order}" == "Order(total=99.5, currency=USD)"
