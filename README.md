## 4*4 16进制数独（Harmony SDK ArkUi练手）

#### 玩法

和9进制数独一样的规则，16进制是把0~F的16进制填入空格

#### 题库生成

使用Python Sudoku 库，修改生成规则和难度、随机种子生成一定数量的谜底

```bash
cd .\python_code_generate_Sudoku\
// 生成数独谜题和对应的解
python .\16Sudo.py
// 调用加密,游戏中解密
python .\decrypt.py
```

#### 截图

| <img src=".\images\main.png" alt="main" style="zoom:20%;" /> | <img src=".\images\ingame.png" style="zoom:20%;" /> | <img src=".\images\game_over.png" style="zoom:20%;" /> | <img src="D:\Mess\project\DevEcoStudioProjects\Sudoku\images\mine.png" style="zoom:20%;" /> | <img src=".\images\rank.png" style="zoom:20%;" /> |
| ------------------------------------------------------------ | --------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------- |

