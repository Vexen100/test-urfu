def print_pack_report(cakes_number):
    for num in range(cakes_number, 0, -1):
        if num % 3 == num % 5 == 0:
            print(f'{num} - расфасуем по 3 или по 5')
        elif num % 3 == 0 and num % 5 != 0:
            print(f'{num} - расфасуем по 3')
        elif num % 3 != 0 and num % 5 == 0:
            print(f'{num} - расфасуем по 5')
        else:
            print(f'{num} - не заказываем!')
