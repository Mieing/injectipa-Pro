#!/bin/bash

# 定义路径
BASE_DIR=$(pwd)/injectipa
IPA_DIR=$BASE_DIR/ipa
DYLIB_DIR=$BASE_DIR/dylib

# 初始化文件夹
mkdir -p "$IPA_DIR"
mkdir -p "$DYLIB_DIR"

echo "========================="
echo "欢迎使用 InjectIPA 脚本工具"
echo "当前工作目录: $BASE_DIR"
echo "请将 IPA 文件放入 $IPA_DIR 文件夹"
echo "请将 DYLIB 文件放入 $DYLIB_DIR 文件夹"
echo "========================="

# 列出 IPA 文件
IPA_FILES=("$IPA_DIR"/*.ipa)
if [ ! -e "${IPA_FILES[0]}" ]; then
  echo "未在 $IPA_DIR 中找到 IPA 文件，请放入 IPA 文件后重新运行脚本。"
  exit 1
fi

echo "找到以下 IPA 文件:"
for i in "${!IPA_FILES[@]}"; do
  echo "$((i + 1)). ${IPA_FILES[$i]##*/}"
done

# 选择 IPA 文件
read -p "请输入要注入的 IPA 文件编号 (默认: 1): " IPA_CHOICE
IPA_CHOICE=${IPA_CHOICE:-1}

# 验证输入是否为有效编号（POSIX 兼容）
if ! echo "$IPA_CHOICE" | grep -qE '^[0-9]+$'; then
  echo "无效的选择：请输入数字。"
  exit 1
fi
if [ "$IPA_CHOICE" -lt 1 ] || [ "$IPA_CHOICE" -gt "${#IPA_FILES[@]}" ]; then
  echo "无效的选择：请输入有效的编号。"
  exit 1
fi

SELECTED_IPA=${IPA_FILES[$((IPA_CHOICE - 1))]}

# 列出 DYLIB 文件
DYLIB_FILES=("$DYLIB_DIR"/*.dylib)
if [ ! -e "${DYLIB_FILES[0]}" ]; then
  echo "未在 $DYLIB_DIR 中找到 DYLIB 文件，请放入 DYLIB 文件后重新运行脚本。"
  exit 1
fi

echo "找到以下 DYLIB 文件:"
for i in "${!DYLIB_FILES[@]}"; do
  echo "$((i + 1)). ${DYLIB_FILES[$i]##*/}"
done

# 选择 DYLIB 文件
read -p "请输入要注入的 DYLIB 文件编号 (空格分隔多个, 默认: 全部): " DYLIB_CHOICE
if [ -z "$DYLIB_CHOICE" ]; then
  SELECTED_DYLIBS=("${DYLIB_FILES[@]}")
else
  SELECTED_DYLIBS=()
  for index in $DYLIB_CHOICE; do
    if ! echo "$index" | grep -qE '^[0-9]+$'; then
      echo "无效的 DYLIB 文件编号：$index。"
      exit 1
    fi
    if [ "$index" -ge 1 ] && [ "$index" -le "${#DYLIB_FILES[@]}" ]; then
      SELECTED_DYLIBS+=("${DYLIB_FILES[$((index - 1))]}")
    else
      echo "无效的 DYLIB 文件编号：$index。"
      exit 1
    fi
  done
fi

# 是否为多开模式
read -p "是否使用多开模式? (默认: 否, 输入 y 开启): " MULTI_MODE
MULTI_MODE=${MULTI_MODE:-n}

# 设置输出文件名
read -p "请输入输出文件名 (默认保持原名): " OUTPUT_NAME
OUTPUT_NAME=${OUTPUT_NAME:-$(basename "$SELECTED_IPA" .ipa)}  # 去掉文件名中的 .ipa 后缀

# 确保输出文件名不为空
if [ -z "$OUTPUT_NAME" ]; then
  echo "未输入输出文件名，将使用默认名称。"
  OUTPUT_NAME="output"
fi

# 设置 Bundle ID
if [ "$MULTI_MODE" = "y" ]; then
  read -p "请输入新的 Bundle ID (默认保持原 ID): " NEW_BUNDLE_ID
  BUNDLE_ID_OPTION=""
  if [ -n "$NEW_BUNDLE_ID" ]; then
    BUNDLE_ID_OPTION="-b $NEW_BUNDLE_ID"
  fi
else
  BUNDLE_ID_OPTION=""
fi

# 设置图标
if [ "$MULTI_MODE" = "y" ]; then
  read -p "请输入新图标文件路径 (默认保持原图标): " NEW_ICON
  ICON_OPTION=""
  if [ -n "$NEW_ICON" ]; then
    ICON_OPTION="-i $NEW_ICON"
  fi
else
  ICON_OPTION=""
fi

# 构造注入命令
INJECT_COMMAND="injectipa \"$SELECTED_IPA\""
for dylib in "${SELECTED_DYLIBS[@]}"; do
  INJECT_COMMAND+=" \"$dylib\""
done

# 添加默认参数
if [ "$MULTI_MODE" = "y" ]; then
  INJECT_COMMAND+=" -s -p -u $BUNDLE_ID_OPTION $ICON_OPTION"
else
  INJECT_COMMAND+=" -p -s"
fi

# 设置输出文件名
INJECT_COMMAND+=" -o \"$OUTPUT_NAME\""

# 用户额外参数
read -p "请输入需要附加的参数 (可选): " EXTRA_PARAMS
if [ -n "$EXTRA_PARAMS" ]; then
  INJECT_COMMAND+=" $EXTRA_PARAMS"
fi

# 执行注入
echo "执行命令: $INJECT_COMMAND"
eval "$INJECT_COMMAND"

# 完成
echo "========================="
echo "注入完成！输出文件位于: $OUTPUT_NAME"
echo "========================="