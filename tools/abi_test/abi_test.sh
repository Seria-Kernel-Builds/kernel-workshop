#!/bin/bash
# run_abi_test.sh
# 作用：封装 simulate_load_kernel_modules.py，一键测试内核与模块的ABI兼容性

set -e

# 配置 Python 脚本的路径
PY_SCRIPT="./simulate_load_kernel_modules.py"

# 帮助信息
if [ "$#" -lt 2 ]; then
    echo "错误: 参数不足！"
    echo "用法: $0 <vmlinux.symvers_路径> <模块所在目录_路径> [设备上的真实模块路径]"
    echo "示例: $0 ./out/vmlinux.symvers ./extracted_dlkm /vendor/lib/modules/"
    exit 1
fi

SYMVERS_FILE="$(realpath "$1")"
MODULES_DIR="$(realpath "$2")"
# 如果未提供设备真实路径，默认使用 /vendor/lib/modules/
REAL_DEVICE_PATH="${3:-/vendor/lib/modules/}"

# 1. 检查必要文件是否存在
if [ ! -f "$SYMVERS_FILE" ]; then
    echo "错误: 找不到符号表文件 $SYMVERS_FILE"
    exit 1
fi

if [ ! -d "$MODULES_DIR" ]; then
    echo "错误: 找不到模块目录 $MODULES_DIR"
    exit 1
fi

if [ ! -f "$MODULES_DIR/modules.load" ] || [ ! -f "$MODULES_DIR/modules.dep" ]; then
    echo "错误: 模块目录下缺失 modules.load 或 modules.dep 文件！"
    echo "请确保它们与 .ko 文件在同一目录: $MODULES_DIR"
    exit 1
fi

# 2. 检查 Python 脚本
if [ ! -f "$PY_SCRIPT" ]; then
    echo "错误: 找不到 Python 测试脚本 $PY_SCRIPT，请确保它在当前目录。"
    exit 1
fi

# 3. 运行测试
echo "================================================="
echo "开始内核模块 ABI 兼容性模拟测试"
echo "内核符号表: $SYMVERS_FILE"
echo "模块目录  : $MODULES_DIR"
echo "映射前缀  : $REAL_DEVICE_PATH"
echo "================================================="

# 调用 Python 脚本
python3 "$PY_SCRIPT" "$SYMVERS_FILE" "$MODULES_DIR/modules.load" "$REAL_DEVICE_PATH"

# 获取返回值
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\n[成功] 所有模块均通过依赖与 CRC 校验！"
elif [ $EXIT_CODE -eq 1 ]; then
    echo -e "\n[失败] 存在符号缺失或 CRC 版本冲突，请查看上方日志报错。"
else
    echo -e "\n[错误] 测试脚本执行异常 (代码: $EXIT_CODE)。"
fi

exit $EXIT_CODE
