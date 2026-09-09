"""Expand input/concurrency axes offline. Emits JSON; never runs a benchmark."""
import argparse
import json


def _positive(value):
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ValueError("Axis values must be positive integers")
    return value


def expand_range(lower, upper, concurrency=False):
    lower, upper = _positive(lower), _positive(upper)
    if lower > upper:
        raise ValueError("Range minimum exceeds maximum")
    values = {lower, upper}
    value = 1
    while value <= upper:
        if lower <= value and (not concurrency or value != 2):
            values.add(value)
        value *= 2
    return sorted(values)


def explicit_axis(values):
    values = [_positive(v) for v in values]
    if not values or len(set(values)) != len(values):
        raise ValueError("Explicit axis must be nonempty and contain no duplicates")
    return values


def build_plan(concurrencies, inputs_k):
    cs, ins = explicit_axis(concurrencies), explicit_axis(inputs_k)
    cells = [{"id": f"in{inp * 1024}-c{c}", "input_tokens": inp * 1024,
              "concurrency": c} for inp in ins for c in cs]
    return {"schema": 1, "status": "awaiting_user_confirmation",
            "k_tokens": 1024, "concurrencies": cs, "inputs_k": ins,
            "cells_per_configuration_per_cache_mode": len(cells),
            "cells": cells}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    cs = parser.add_mutually_exclusive_group(required=True)
    cs.add_argument("--concurrency-range", nargs=2, type=int)
    cs.add_argument("--concurrencies", nargs="+", type=int)
    ins = parser.add_mutually_exclusive_group(required=True)
    ins.add_argument("--input-k-range", nargs=2, type=int)
    ins.add_argument("--inputs-k", nargs="+", type=int)
    args = parser.parse_args()
    try:
        c = (expand_range(*args.concurrency_range, concurrency=True)
             if args.concurrency_range else args.concurrencies)
        i = expand_range(*args.input_k_range) if args.input_k_range else args.inputs_k
        result = build_plan(c, i)
    except ValueError as error:
        parser.error(str(error))
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
