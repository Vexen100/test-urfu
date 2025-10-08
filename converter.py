def to_roman(arab_number): # преобразование арабских цифр в римские (на вход принимает целое число в форме строки)
    arab_number = int(arab_number)
    roman_dict = {1: 'I', 4: 'IV', 5: 'V', 9: 'IX', 10: 'X',  40: 'XL', 50: 'L',
                  90: 'XC', 100: 'C', 400: 'CD', 500: 'D', 900: 'CM', 1000: 'M'}
    result_roman = ''
    for num in reversed(roman_dict.keys()):
        while arab_number >= num:
            result_roman += roman_dict[num]
            arab_number -= num
    return result_roman

def to_arab(roman_number): # преобразование римских цифр в арабские (на вход принимает строку - римское число)
    arab_dict = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}
    result_arab = 0
    prev_char = 0
    for char in reversed(roman_number):
        current_char = arab_dict[char]
        if current_char < prev_char:
            result_arab -= current_char
        else:
            result_arab += current_char
        prev_char = current_char

    return result_arab

operation = input('Выберите операцию (1 - из римских в арабские, 2 - из арабских в римские): ')
while operation not in ('1', '2'):
    operation = input('Неверно! Выберите операцию (1 - из римских в арабские, 2 - из арабских в римские): ')

data_list = [elem.strip() for elem in input('Введите список чисел через запятую (если число одно, то просто введите его): ').split(',')]

result = []
if operation == '1':
    for number in data_list:
        result.append(to_arab(number))
else:
    for number in data_list:
        result.append(to_roman(number))

print(result)

