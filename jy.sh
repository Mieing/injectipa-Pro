#!/bin/bash

# 获取当前目录
current_dir=$(pwd)

# 查找当前目录下的所有 .zip 文件
zip_files=($current_dir/*.zip)

# 检查是否有 .zip 文件
if [ ${#zip_files[@]} -eq 0 ]; then
    echo "当前目录没有找到任何 .zip 文件！"
    exit 1
fi

# 如果有多个 .zip 文件，显示选项
echo "找到以下 .zip 文件："
for i in "${!zip_files[@]}"; do
    echo "$((i + 1)). ${zip_files[i]}"
done

# 提示用户选择
echo "请输入数字选择要处理的 .zip 文件（1-${#zip_files[@]}）："
read choice

# 检查输入的选择是否合法
if [[ ! "$choice" =~ ^[1-9]$ ]] || [ "$choice" -gt "${#zip_files[@]}" ]; then
    echo "无效选择，请输入有效的数字。"
    exit 1
fi

# 获取选择的文件
zip_file="${zip_files[$((choice - 1))]}"

# 定义解压目标文件夹路径和 dylib 文件夹路径
extracted_dir="/var/mobile/Documents/extracted"
dylib_dir="/var/mobile/Documents/dylibs"

# 创建目标文件夹（如果不存在的话）
mkdir -p "$extracted_dir"
mkdir -p "$dylib_dir"

# 检查 unzip 和 dpkg-deb 是否安装
if ! command -v unzip &>/dev/null; then
    echo "找不到 unzip 命令，请安装它。"
    exit 1
fi

if ! command -v dpkg-deb &>/dev/null; then
    echo "找不到 dpkg-deb 命令，请安装它。"
    exit 1
fi

# 解压选中的 zip 文件
unzip -o "$zip_file" -d "$extracted_dir"

# 删除所有的 __MACOSX 文件夹
find "$extracted_dir" -type d -name "__MACOSX" -exec rm -rf {} +

# 查找解压后的 .deb 文件并解压
find "$extracted_dir" -name "*.deb" | while read deb_file; do
    # 清理目标解压目录，避免路径冲突
    rm -rf "$extracted_dir/deb_contents"

    # 使用 dpkg-deb 解压 .deb 文件
    dpkg-deb -R "$deb_file" "$extracted_dir/deb_contents"
    
    # 查找解压后的文件夹中的所有 dylib 文件
    find "$extracted_dir/deb_contents" -type f -name "*.dylib" | while read dylib_file; do
        # 将所有 dylib 文件复制到目标 dylibs 文件夹
        cp "$dylib_file" "$dylib_dir"
    done
done

# 查找 Documents 文件夹下所有 .dylib 文件并移动到目标 dylibs 文件夹
find "/var/mobile/Documents" -type f -name "*.dylib" | while read dylib_file; do
    # 将所有找到的 dylib 文件复制到目标 dylibs 文件夹
    cp "$dylib_file" "$dylib_dir"
done

# 删除临时文件夹
rm -rf "$extracted_dir"

echo "所有 dylib 文件已集中到 $dylib_dir，临时文件夹已删除"
