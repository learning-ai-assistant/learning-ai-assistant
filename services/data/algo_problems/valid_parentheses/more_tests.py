# Пример 4
s = "([])"
result = solution.isValid(s)
assert result

# Пример 5
s = "([)]"
result = solution.isValid(s)
assert not result

# Тест
s = "["
result = solution.isValid(s)
assert not result

# Тест
s = "]"
result = solution.isValid(s)
assert not result