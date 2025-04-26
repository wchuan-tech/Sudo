import os

def xor_encrypt_decrypt(content, key):
    # 使用给定的 key 对内容进行异或加密/解密
    return ''.join(chr(ord(char) ^ key) for char in content)

def process_txt_files(source_dir, destination_dir, key=42):
    # 如果目标目录不存在，则创建
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)

    # 遍历源目录中的所有文件
    for root, _, files in os.walk(source_dir):
        for file_name in files:
            if file_name.endswith(".txt"):
                # 构造完整的文件路径
                file_path = os.path.join(root, file_name)
                
                # 读取文件内容
                with open(file_path, 'r', encoding='utf-8') as file:
                    content = file.read()
                
                # 加密内容
                encrypted_content = xor_encrypt_decrypt(content, key)
                
                # 保存到目标目录
                relative_path = os.path.relpath(root, source_dir)
                target_path = os.path.join(destination_dir, relative_path)
                
                # 如果目标子目录不存在，则创建
                if not os.path.exists(target_path):
                    os.makedirs(target_path)
                
                # 保存加密后的文件
                target_file_path = os.path.join(target_path, file_name)
                with open(target_file_path, 'w', encoding='utf-8') as file:
                    file.write(encrypted_content)
                
                print(f"已处理文件：{file_path} -> {target_file_path}")

# 使用示例
source_directory = input()  # 原文件夹路径
destination_directory = source_directory + "_data"  # 保存加密文件的目标文件夹路径
xor_key = 1618  # 异或加密的密钥

process_txt_files(source_directory, destination_directory, xor_key)
