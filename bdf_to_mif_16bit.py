import sys
import os

def parse_bdf(bdf_file_path):
    """
    解析 BDF 文件，提取每个字符的 8x8 行像素数据。
    返回一个字典，键是 ASCII 码，值是8个十六进制字符串的列表。
    """
    font_data_rows = {}
    try:
        with open(bdf_file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"错误: BDF 文件未找到 -> {bdf_file_path}")
        return None

    char_data = None
    in_bitmap = False
    for line in lines:
        line = line.strip()
        if line.startswith('ENCODING'):
            try:
                ascii_code = int(line.split()[1])
                # We are interested in standard printable ASCII characters
                if 32 <= ascii_code < 127:
                    char_data = {'code': ascii_code, 'bitmap_rows': []}
            except (ValueError, IndexError):
                char_data = None
        elif line.startswith('BITMAP'):
            if char_data is not None:
                in_bitmap = True
        elif line.startswith('ENDCHAR'):
            if char_data and len(char_data['bitmap_rows']) > 0:
                # 确保数据是8行，不足则补0
                while len(char_data['bitmap_rows']) < 8:
                    char_data['bitmap_rows'].append("00")
                font_data_rows[char_data['code']] = char_data['bitmap_rows'][:8]
            in_bitmap = False
            char_data = None
        elif in_bitmap and char_data:
            # BDF 字体通常只有实际内容的高度，我们需要处理8像素高度的情况
            if len(char_data['bitmap_rows']) < 8:
                char_data['bitmap_rows'].append(line)

    return font_data_rows

def convert_and_write_mif(font_data_rows, output_mif_path):
    """
    将行数据转换为列数据，组合成16位的字，并为可见字符写入 MIF 文件。
    """
    print("开始为可见字符生成 16-bit MIF 文件...")
    
    # 定义可见字符的ASCII范围 (空格到~)
    PRINTABLE_ASCII_START = 32
    PRINTABLE_ASCII_END = 126
    NUM_CHARS = PRINTABLE_ASCII_END - PRINTABLE_ASCII_START + 1

    with open(output_mif_path, 'w', encoding='utf-8') as f:
        # 写入 MIF 文件头
        f.write(f"-- Printable ASCII Font Library for UFM ({NUM_CHARS} Chars, {NUM_CHARS*4} Words total)\n")
        f.write("-- Generated for 16-bit data width UFM\n\n")
        f.write("WIDTH = 16;\n")
        f.write(f"DEPTH = {NUM_CHARS * 4};\n") # 设置精确的深度
        f.write("ADDRESS_RADIX = DEC;\n")
        f.write("DATA_RADIX = HEX;\n\n")
        f.write("CONTENT BEGIN\n")

        # 遍历所有可见ASCII码
        for ascii_code in range(PRINTABLE_ASCII_START, PRINTABLE_ASCII_END + 1):
            char_rows = font_data_rows.get(ascii_code)
            
            # 获取字符名称用于注释
            char_name = 'Space' if ascii_code == 32 else chr(ascii_code)

            f.write(f"    -- ASCII {ascii_code}: Char '{char_name}'\n")
            
            if not char_rows:
                print(f"警告: 字体库中未找到 ASCII {ascii_code} ('{char_name}') 的数据, 将使用全0填充。")
                char_rows = ["00"] * 8

            # 核心转换逻辑：行数据 -> 列数据
            pixel_matrix = []
            for row_hex in char_rows:
                binary_row = bin(int(row_hex, 16))[2:].zfill(8)
                pixel_matrix.append([int(b) for b in binary_row])

            column_hex_data = []
            for col in range(8):
                binary_col_chars = [str(pixel_matrix[row][col]) for row in range(8)]
                binary_col_string = "".join(reversed(binary_col_chars))
                col_hex = hex(int(binary_col_string, 2))[2:].upper().zfill(2)
                column_hex_data.append(col_hex)
            
            # 将8个8位的列数据两两组合成4个16位的字
            for i in range(4):
                low_byte_index = i * 2
                high_byte_index = i * 2 + 1
                low_byte_hex = column_hex_data[low_byte_index]
                high_byte_hex = column_hex_data[high_byte_index]
                word_hex = high_byte_hex + low_byte_hex
                
                # 地址计算: (ASCII码 - 偏移量) * 4 + 字索引
                address = (ascii_code - PRINTABLE_ASCII_START) * 4 + i
                f.write(f"    {address} : {word_hex};\n")
            
            if ascii_code < PRINTABLE_ASCII_END:
                f.write("\n")

        f.write("END;\n")
    print(f"成功！MIF 文件已生成 -> {output_mif_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使用方法: python bdf_to_mif_16bit.py <输入bdf文件名> <输出mif文件名>")
        sys.exit(1)
    
    bdf_input = sys.argv[1]
    mif_output = sys.argv[2]
    
    parsed_data = parse_bdf(bdf_input)
    if parsed_data:
        convert_and_write_mif(parsed_data, mif_output)

