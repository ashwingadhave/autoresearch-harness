from calcpkg import calc


def test_add():
    assert calc.add(2, 3) == 5


def test_subtract():
    assert calc.subtract(5, 3) == 2


def test_divide_happy_path():
    assert calc.divide(10, 4) == 2.5


def test_clamp_inside_range():
    assert calc.clamp(5, 1, 10) == 5
