detect_os() {
    echo "linux"
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv7l"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID:-}" in
            ubuntu)
                echo "ubuntu"
                ;;
            debian)
                echo "debian"
                ;;
            fedora)
                echo "fedora"
                ;;
            centos)
                echo "centos"
                ;;
            rhel|redhat)
                echo "rhel"
                ;;
            arch|archlinux)
                echo "arch"
                ;;
            alpine)
                echo "alpine"
                ;;
            opensuse|suse)
                echo "suse"
                ;;
            *)
                echo "${ID:-unknown}"
                ;;
        esac
    elif [[ -f /etc/redhat-release ]]; then
        if grep -q "Fedora" /etc/redhat-release; then
            echo "fedora"
        elif grep -q "CentOS" /etc/redhat-release; then
            echo "centos"
        else
            echo "rhel"
        fi
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/alpine-release ]]; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo ""
    fi
}

get_install_command() {
    local pkg_mgr
    pkg_mgr=$(detect_package_manager)
    case "$pkg_mgr" in
        apt)
            echo "apt-get install -y"
            ;;
        dnf)
            echo "dnf install -y"
            ;;
        yum)
            echo "yum install -y"
            ;;
        pacman)
            echo "pacman -S --noconfirm"
            ;;
        apk)
            echo "apk add"
            ;;
        brew)
            echo "brew install"
            ;;
        *)
            echo ""
            ;;
    esac
}
