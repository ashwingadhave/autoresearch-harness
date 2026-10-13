def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def divide(a, b):
    if b == 0:
        raise ZeroDivisionError("cannot divide by zero")
    return a / b


def percent(part, whole):
    if whole == 0:
        return 0.0
    return round(100.0 * part / whole, 2)


def clamp(value, low, high):
    if low > high:
        raise ValueError("low must not exceed high")
    if value < low:
        return low
    if value > high:
        return high
    return value


def is_even(n):
    if not isinstance(n, int):
        raise TypeError("n must be an int")
    return n % 2 == 0
