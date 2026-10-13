import re


def slugify(text):
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def truncate(text, limit, suffix="..."):
    if limit < 0:
        raise ValueError("limit must be >= 0")
    if len(text) <= limit:
        return text
    if limit <= len(suffix):
        return text[:limit]
    return text[: limit - len(suffix)] + suffix


def word_count(text):
    if not text or not text.strip():
        return 0
    return len(text.split())


def initials(full_name):
    parts = [p for p in full_name.split() if p]
    if not parts:
        return ""
    return "".join(p[0].upper() for p in parts)
