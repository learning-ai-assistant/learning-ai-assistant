from services.data.algo_problems.valid_parentheses.solution_deque import Solution

def test():
    solution = Solution()
    
    # Пример 1
    s = "()"
    result = solution.isValid(s)
    assert result
    
    # Пример 2
    s = "()[]{}"
    result = solution.isValid(s)
    assert result
    
    # Пример 3
    s = "(]"
    result = solution.isValid(s)
    assert not result

    inputs = ["{][}", "([)]", "(){}[]", "({)", "])"]
    results = [False, False, True, False, False]
    for input, result in zip(inputs, results):
        sol_result = solution.isValid(input)
        assert sol_result == result

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
    

if __name__ == "__main__":
    test()
