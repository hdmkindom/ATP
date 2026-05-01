#!/usr/bin/env bash
set -euo pipefail

# ATP 一键安装脚本（Linux / macOS）
# 目标：
# 1. 检查基础命令是否存在
# 2. 按需安装 Elan
# 3. 创建 Python 虚拟环境
# 4. 安装 ATP / ax-prover 所需 Python 依赖
# 5. 执行 `lake build` 与 ATP 零依赖测试

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${ATP_ROOT}/.." && pwd)"
DEFAULT_VENV_PATH="${ATP_VENV_PATH:-$HOME/ax-prover-env}"

VENV_PATH="${DEFAULT_VENV_PATH}"
SKIP_BUILD=0
SKIP_TESTS=0

usage() {
  cat <<EOF
用法：
  bash ATP/scripts/install_atp.sh [--venv-path PATH] [--skip-build] [--skip-tests]

参数：
  --venv-path PATH   指定 Python 虚拟环境目录，默认：${DEFAULT_VENV_PATH}
  --skip-build       跳过 lake build
  --skip-tests       跳过 ATP/tests/run_tests.py
  -h, --help         显示帮助
EOF
}

log_info() {
  printf '[INFO] %s\n' "$1"
}

log_warn() {
  printf '[WARN] %s\n' "$1"
}

log_error() {
  printf '[ERROR] %s\n' "$1" >&2
}

require_command() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    log_error "缺少命令：${cmd}。${hint}"
    exit 1
  fi
}

detect_platform() {
  local os_name
  os_name="$(uname -s)"
  case "${os_name}" in
    Darwin)
      log_info "检测到 macOS。"
      ;;
    Linux)
      log_info "检测到 Linux。"
      ;;
    *)
      log_error "当前平台 ${os_name} 不在此脚本支持范围内。请改用 README 中的手动部署流程。"
      exit 1
      ;;
  esac
}

ensure_elan() {
  if command -v elan >/dev/null 2>&1; then
    log_info "检测到 Elan，跳过安装。"
  else
    require_command "curl" "Elan 安装脚本依赖 curl。"
    log_info "未检测到 Elan，开始安装。"
    curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y
  fi

  if [ -f "$HOME/.elan/env" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.elan/env"
  fi

  require_command "elan" "请确认 Elan 安装成功。"
  require_command "lake" "请确认 Lean 工具链已由 Elan 初始化完成。"
  require_command "lean" "请确认 Lean 工具链可用。"
}

ensure_python_venv() {
  require_command "python3" "请先安装 Python 3.11 或更高版本。"
  require_command "git" "请先安装 Git。"

  log_info "创建或复用虚拟环境：${VENV_PATH}"
  python3 -m venv "${VENV_PATH}"

  # shellcheck disable=SC1090
  source "${VENV_PATH}/bin/activate"

  log_info "升级 pip。"
  python -m pip install --upgrade pip

  log_info "安装 Python 依赖：ax-prover, omegaconf, langchain-deepseek"
  pip install ax-prover omegaconf langchain-deepseek
}

run_build() {
  if [ "${SKIP_BUILD}" -eq 1 ]; then
    log_warn "按参数要求跳过 lake build。"
    return
  fi

  log_info "执行 lake build。"
  (
    cd "${REPO_ROOT}"
    lake build
  )
}

run_tests() {
  if [ "${SKIP_TESTS}" -eq 1 ]; then
    log_warn "按参数要求跳过 ATP/tests/run_tests.py。"
    return
  fi

  log_info "执行 ATP 零依赖测试。"
  (
    cd "${REPO_ROOT}"
    python ATP/tests/run_tests.py
  )
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --venv-path)
        if [ "$#" -lt 2 ]; then
          log_error "--venv-path 需要一个路径参数。"
          exit 1
        fi
        VENV_PATH="$2"
        shift 2
        ;;
      --skip-build)
        SKIP_BUILD=1
        shift
        ;;
      --skip-tests)
        SKIP_TESTS=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "未知参数：$1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  detect_platform
  ensure_elan
  ensure_python_venv
  run_build
  run_tests

  log_info "ATP 环境初始化完成。"
  log_info "后续可执行：source ${VENV_PATH}/bin/activate"
  log_info "然后运行：python ATP/scripts/atp_axbench.py doctor --skip-proof"
}

main "$@"
