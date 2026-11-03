from drive_sync.sources import safe_name
from drive_sync.drive import _escape


def test_safe_name():
    assert safe_name('Re: a/b*c?') == "Re_ a_b_c_"
    assert safe_name("") == "untitled"
    assert len(safe_name("x" * 500)) == 80


def test_escape_quotes():
    assert _escape("it's") == "it\\'s"
