"""Offline regression checks for matrix expansion, no model or cloud access."""
import unittest
from build_matrix_plan import build_plan, expand_range


class MatrixPlanTests(unittest.TestCase):
    def test_requested_36_cells(self):
        cs = expand_range(1, 64, concurrency=True)
        ins = expand_range(8, 256)
        self.assertEqual(cs, [1, 4, 8, 16, 32, 64])
        self.assertEqual(ins, [8, 16, 32, 64, 128, 256])
        plan = build_plan(cs, ins)
        self.assertEqual(plan["cells_per_configuration_per_cache_mode"], 36)
        expected = {(i * 1024, c) for i in ins for c in cs}
        self.assertEqual({(r["input_tokens"], r["concurrency"])
                          for r in plan["cells"]}, expected)
        self.assertEqual(len({r["id"] for r in plan["cells"]}), 36)

    def test_explicit_axes_preserved(self):
        plan = build_plan([1, 2, 48], [8, 96])
        self.assertEqual(plan["concurrencies"], [1, 2, 48])
        self.assertEqual(len(plan["cells"]), 6)

    def test_range_endpoints_preserved(self):
        self.assertEqual(expand_range(2, 48, concurrency=True), [2, 4, 8, 16, 32, 48])
        self.assertEqual(expand_range(12, 96), [12, 16, 32, 64, 96])

    def test_invalid_ranges(self):
        for lower, upper in [(0, 64), (64, 1), (-1, 8)]:
            with self.assertRaises(ValueError):
                expand_range(lower, upper)

    def test_invalid_explicit_axes(self):
        for values in [[], [1, 1], [True], [1.5], [0]]:
            with self.assertRaises(ValueError):
                build_plan(values, [8])


if __name__ == "__main__":
    unittest.main()
