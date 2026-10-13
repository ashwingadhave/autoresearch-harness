from calcpkg import strings


def test_slugify_basic():
    assert strings.slugify("Hello World!") == "hello-world"


def test_word_count_basic():
    assert strings.word_count("one two three") == 3
