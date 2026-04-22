from services.data.algo_problems.minimum_size_subarray_sum.solution import Solution

def test():
    solution = Solution()
    
    # Пример 1 четное число элементов, подмассив из 2х элементов в конце
    target = 7
    nums = [2,3,1,2,4,3]
    write_ans = 2
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Пример 2 нечетное число элементов, подмассив из 1го элемента в середине
    target = 4
    nums = [1,4,4]
    write_ans = 1
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Пример 3 четное число элементов, подмассива с нужной суммой нет
    target = 11
    nums = [1,1,1,1,1,1,1,1]
    write_ans = 0
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Тест массив из 1 элемента, нет подмассива
    target = 5
    nums = [1]
    write_ans = 0
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Тест массив из 1 элемента, подмассив из 1 элемента
    target = 1
    nums = [1]
    write_ans = 1
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Тест массив из 6 элементов, подмассив из 1 элемента
    # дубли из чисел превышающих таргет
    target = 5
    nums = [1, 7, 7, 8, 1, 1]
    write_ans = 1
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Тест с большим target
    target = 1000000000
    nums = [1, 2, 3, 4, 5] * 10000  # Большой массив
    write_ans = 0  # Ожидаем 0, так как сумма всех элементов меньше target
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Тест с target равным первому элементу
    target = 5
    nums = [5, 1, 1, 1, 1]
    write_ans = 1
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    # Тест, где минимальный подмассив находится в конце
    target = 5
    nums = [1, 1, 1, 1, 6]
    write_ans = 1
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans

    
    # Тест с target равным сумме всех элементов
    target = 15
    nums = [1, 2, 3, 4, 5]
    write_ans = 5
    
    min_subarray_len = solution.minSubArrayLen(target, nums)
    assert min_subarray_len == write_ans
    
    
if __name__ == "__main__":
    test()