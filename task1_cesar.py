import string


ru_alphabet = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
en_alphabet = string.ascii_lowercase

text_orig = input("Введите текст для обработки: ")
operation = input("Напишите 1, если требуется зашифровать текст, или 2, если нужно расшифровать: ")
shift = int(input("Напишите число, на которое будет осуществляться сдвиг (оно не должно превышать длину алфавита (26 для англ., 33 для рус.)): "))
shiftDirection = input("Напишите направление сдвига при шифровании (left или right): ")
lang = "ru" if text_orig[0].lower() in ru_alphabet else "en"
alphabet = ru_alphabet if lang == "ru" else en_alphabet
alphabet_length = len(alphabet)
text = text_orig.lower()

def  shift_encryption(index1, shift_num): # рассчёт индекса после сдвига при шифровании
    if shiftDirection == "right":
        return index1 + shift_num
    else:
        return index1 - shift_num

def  shift_decryption(index1, shift_num): # рассчёт индекса после сдвига при расшифровке
    if shiftDirection == "right":
        return index1 - shift_num
    else:
        return index1 + shift_num

def encryption(original_text):
    result_text = ""
    for letter in original_text:
        if not letter.isalpha():
            result_text += letter
            continue
        index = alphabet.index(letter)
        pre_result_ind = shift_encryption(index, shift)
        # right сдвиг
        if shiftDirection == "right":
            if pre_result_ind >= alphabet_length:
                result_index = pre_result_ind - alphabet_length
            else:
                result_index = pre_result_ind
        # left сдвиг
        else:
            result_index = pre_result_ind
        result_text += alphabet[result_index]
    return result_text



def decryption(original_text):
    result_text = ""
    for letter in original_text:
        if not letter.isalpha():
            result_text += letter
            continue
        index = alphabet.index(letter)
        pre_result_ind = shift_decryption(index, shift)
        # right сдвиг
        if shiftDirection == "left":
            if pre_result_ind >= alphabet_length:
                result_index = pre_result_ind - alphabet_length
            else:
                result_index = pre_result_ind
        # left сдвиг
        else:
            result_index = pre_result_ind
        result_text += alphabet[result_index]
    return result_text

result = encryption(text) if operation == "1" else decryption(text)
final_result = ''.join([result[ind].upper() if text_orig[ind].isupper() and result[ind].isalpha() else result[ind] for ind in range(len(result))]) # возвращение символов к изначальному регистру

print("Операция успешно завершена! Результат:", final_result, sep='\n')
