def find_general_elem(array: list[int]) -> int:
    """Функция ищет элемент массива, который встречается больше половины
    раз в массиве, используя алгоритм Бойера-Мура.

    Если такой элемент существует, - возвращает его.
    Если такого элемента нет, - возвращает -1.

    Временная сложность O(n) - два прохода по массиву.
    Пространственная сложность O(1) - используем только несколько переменных.

    Args:
        array (list[int]): массив целых чисел.

    Returns:
        int: значение элемента, который встречается больше половины
            раз в массиве или -1, если такого элемента нет.
    """
    if not array:
        return -1

    # поиск самого часто встречающегося элемента
    candidate = None
    count = 0

    for number in array:
        if count == 0:
            candidate = number
            count = 1
        else:
            if number == candidate:
                count += 1
            else:
                count -= 1

    # проверка кандидата, что встречается больше половины
    # раз в массиве
    count = 0
    for number in array:
        if number == candidate:
            count += 1

    if count > len(array) / 2:
        return candidate
    else:
        return -1


if __name__ == "__main__":
    array_len = int(input())
    array = list(map(int, input().split()))
    general_elem = find_general_elem(array)
    print(general_elem)
