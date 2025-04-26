from sudoku import Sudoku
import random
import os
import time
def replace_value(row):
    replace_dict = {
        1: '1',
        2: '2',
        3: '3',
        4: '4',
        5: '5',
        6: '6',
        7: '7',
        8: '8',
        9: '9',
        10: 'A',
        11: 'B',
        12: 'C',
        13: 'D',
        14: 'E',
        15: 'F',
        16: '0',
        None:'Z'
    }

    # 替换数值
    # converted_board = [[replace_dict.get(num, num) for num in row] for row in sudoku_board]
    new_row = [replace_dict.get(num, num) for num in row]
    # print("转换后的数独表格：")
    # print(row)
    # print(new_row)
    return new_row

random_numbers = random.sample(range(1, 300), 100)

folder_path = "result"
# os.mkdir(folder_path)
if not os.path.exists(folder_path):
    os.makedirs(folder_path)

# 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7
for i in range(1, 101) :
    # 默认使用系统时间作为种子
    # 生成一个数独谜题，并确保只有一个解
    curSeed = random_numbers[i - 1]
    print('curSeed = ', curSeed)
    puzzle = Sudoku(4, seed=curSeed).difficulty(0.6)
    solution = puzzle.solve()
    # print("生成的数独谜题：")
    # print(puzzle)
    
    filename = f"result/{i}.txt"
    
    with open(filename, "w", encoding='utf-8') as file:
        # 打印数独谜题表格
        file.write("puzzle：\n")
        for row in puzzle.board:
            file.write(" ".join(replace_value(row)) + "\n")
        print('--------------------------------------------------')
        # 获取谜题的解
        # print("\n数独谜题的解：")
        # print(solution)
        file.write("solution：\n")
        for row in solution.board:
            file.write(" ".join(replace_value(row)) + "\n")
