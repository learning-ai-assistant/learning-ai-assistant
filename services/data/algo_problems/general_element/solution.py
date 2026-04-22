from collections import defaultdict


def find_general_elem(array: list[int]) -> int:
    """Функция ищет элемента массива, который встречается больше половины
    раз в массиве.

    Если такой элемент существует, - возвращает его.
    Если такого элемента нет, - возвращает -1.

    Временная сложность O(n) - один проход по всем элементам массива.

    Пространственная сложность O(n) - создаем хеш таблицу для подсчета
    количества каждого уникального символа в массиве.

    Args:
        array (list[int]): массив целых чисел.

    Returns:
        int: значение элемента, который встречается больше половины
            раз в массиве или -1, если такого элемента нет.
    """
    numbers_dct = defaultdict(int)
    array_len_half = len(array) / 2

    for number in array:
        numbers_dct[number] += 1
        if numbers_dct[number] > array_len_half:
            return number

    return -1


if __name__ == "__main__":
    array_len = int(input())
    array = list(map(int, input().split()))
    general_elem = find_general_elem(array)
    print(general_elem)
