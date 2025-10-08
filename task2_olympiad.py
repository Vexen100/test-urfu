scores_list = list(map(int, input('Введите список баллов участников через запятую: ').split(',')))
score_stas = int(input('Введите баллы Стаса: '))

def check_winners(scores, student_score):
    ordered_scores = sorted(scores, reverse=True)
    if student_score in ordered_scores[:3]:
        print('Вы в тройке победителей!')
    else:
        print('Вы не попали в тройку победителей.')

check_winners(scores_list, score_stas)
