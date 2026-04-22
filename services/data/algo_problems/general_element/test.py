from services.data.algo_problems.general_element.solution2 import find_general_elem


def test():
    # Пример нечетная длинна массива элемент есть
    array = [7, 7, 8, 8, 8, 8, 9]
    right_answer = 8
    run_one_test(array, right_answer)

    # Тест четная длинна массива элемент есть
    array = [7, 8, 8, 8, 8, 8]
    right_answer = 8
    run_one_test(array, right_answer)

    # Тест четная длинна массива, элемента нет
    array = [1, 2, 3, 4, 5, 6]
    right_answer = -1
    run_one_test(array, right_answer)

    # Тест массив длины в 1 элемент
    array = [1]
    right_answer = 1
    run_one_test(array, right_answer)

    # Тест пустой массив
    array = []
    right_answer = -1
    run_one_test(array, right_answer)

    # Массив с отрицательными числами
    array = [-1, -1, -2, -2, -2]
    right_answer = -2
    run_one_test(array, right_answer)

    # Все элементы одинаковые
    array = [5, 5, 5, 5]
    right_answer = 5
    run_one_test(array, right_answer)

    # Граничный случай: majority ровно n/2 + 1
    array = [1, 1, 1, 2, 2]
    right_answer = 1
    run_one_test(array, right_answer)
    
    # Тест, где majority элемент не сразу становится кандидатом
    array = [2, 2, 3, 3, 3, 2, 2]
    right_answer = 2
    run_one_test(array, right_answer)


def run_one_test(array, right_answer):
    print()
    print(f"array:{array}")
    print(f"right_answer:{right_answer}")
    general_elem = find_general_elem(array)
    assert general_elem == right_answer
    print(f"general_elem:{general_elem}")


if __name__ == "__main__":
    test()
