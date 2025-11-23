#!/bin/bash

# i3 Debian Customization Script (inspired by Hyprland workflow)
# Last updated: 2025-11-23

set -e  # exit on error

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"  # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# تأكد من تشغيله كمستخدم عادي (ليس root)
if [ "$EUID" -eq 0 ]; then
    error "لا تقم بتشغيل هذا السكريبت كـ root. استخدم مستخدم عادي مع صلاحيات sudo."
fi

# التحديث الأولي
log "جارٍ تحديث النظام..."
sudo apt update && sudo apt upgrade -y

# الحزم الأساسية
log "تثبيت الحزم المطلوبة..."

PKGS=(
    i3-wm
    i3status
    i3blocks
    rofi
    feh
    picom
    dunst
    alacritty
    thunar
    lxappearance
    fonts-firacode
    fonts-font-awesome
    fonts-noto-color-emoji
    playerctl
    brightnessctl
    pulseaudio-utils
    network-manager-gnome
    xbacklight
    acpi
    curl
    wget
    git
    neofetch
)

# إضافة مستودعات لبعض الأدوات (مثل polybar إذا أردت لاحقًا)
# لكن سنستخدم i3blocks الآن لتبسيط الأمور

sudo apt install -y "${PKGS[@]}" || error "فشل تثبيت الحزم"

# إنشاء مجلدات التكوين
CONFIG_DIR="$HOME/.config"
I3_DIR="$CONFIG_DIR/i3"
I3STATUS_DIR="$CONFIG_DIR/i3status"
DUNST_DIR="$CONFIG_DIR/dunst"
ALACRITTY_DIR="$CONFIG_DIR/alacritty"

mkdir -p "$I3_DIR" "$I3STATUS_DIR" "$DUNST_DIR" "$ALACRITTY_DIR"

# === تكوين i3 ===
log "إعداد ملف تكوين i3..."

cat > "$I3_DIR/config" << 'EOF'
# i3 config file (v4)

font pango: FiraCode Nerd Font 10

# استخدام وحدة i3-gaps (إن كنت تستخدم i3-gaps، وإلا احذف هذه السطور)
# gaps inner 10
# gaps outer 0

# الألوان (نمط حديث)
client.focused          #5e81ac #5e81ac #2e3440 #5e81ac
client.focused_inactive #4c566a #4c566a #eceff4 #4c566a
client.unfocused        #434c5e #434c5e #d8dee9 #434c5e
client.urgent           #bf616a #bf616a #ffffff #bf616a
client.placeholder      #2e3440 #2e3440 #d8dee9 #2e3440

# اختصارات لوحة المفاتيح
set $mod Mod4

# تشغيل التطبيقات
bindsym $mod+Return exec alacritty
bindsym $mod+d exec rofi -show drun
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'هل تريد الخروج؟' -B 'نعم، اخرج' 'i3-msg exit'"

# التنقل
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# تحريك النوافذ
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# تقسيم الواجهة
bindsym $mod+b split h
bindsym $mod+v split v

# وضع ملء الشاشة
bindsym $mod+f fullscreen toggle

# وضع浮动
bindsym $mod+Shift+space floating toggle

# تغيير حجم النوافذ
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt

    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt

    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# شريط الحالة
bar {
    status_command i3blocks
    font pango:FiraCode Nerd Font 9
    position top
    tray_output primary
}
EOF

# === تكوين i3blocks ===
log "إعداد i3blocks..."

cat > "$I3_DIR/i3blocks.conf" << 'EOF'
[volume]
label=VOL
command=~/.config/i3blocks/volume.sh
interval=once
signal=10

[brightness]
label=BRG
command=~/.config/i3blocks/brightness.sh
interval=once
signal=11

[time]
command=date '+%a %d %b %H:%M'
interval=5

[cpu]
command=top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
interval=5
label=CPU:

[memory]
command=free -m | awk '/^Mem:/ { printf("%.1f%%", $3/$2*100) }'
interval=10
label=MEM:

[network]
command=~/.config/i3blocks/network.sh
interval=10

[battery]
command=~/.config/i3blocks/battery.sh
interval=30
EOF

# إنشاء مجلد السكريبتات
mkdir -p "$I3_DIR/i3blocks"

# سكريبت الصوت
cat > "$I3_DIR/i3blocks/volume.sh" << 'EOF'
#!/bin/sh
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | cut -f2 -d' ' | tr -d '%')
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | cut -d' ' -f2)
if [ "$MUTE" = "yes" ]; then
    echo "MUTE"
else
    echo "$VOL%"
fi
EOF

# سكريبت السطوع
cat > "$I3_DIR/i3blocks/brightness.sh" << 'EOF'
#!/bin/sh
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))
echo "$PERCENT%"
EOF

# سكريبت الشبكة
cat > "$I3_DIR/i3blocks/network.sh" << 'EOF'
#!/bin/sh
IFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
if [ -n "$IFACE" ]; then
    IP=$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | cut -d'/' -f1 | head -n1)
    echo " $IP"
else
    echo "Disconnected"
fi
EOF

# سكريبت البطارية
cat > "$I3_DIR/i3blocks/battery.sh" << 'EOF'
#!/bin/sh
BATT=$(acpi -b | grep -oP 'Battery [0-9]+: \K[^,]*')
PERC=$(acpi -b | grep -oP '([0-9]+)(?=%)')
if [ "$BATT" = "Full" ]; then
    echo " $PERC%"
elif [ "$BATT" = "Discharging" ]; then
    echo " $PERC%"
else
    echo " $PERC%"
fi
EOF

# إعطاء صلاحيات تنفيذ للسكريبتات
chmod +x "$I3_DIR"/i3blocks/*.sh

# === تكوين Dunst (الإشعارات) ===
log "إعداد Dunst..."

cat > "$DUNST_DIR/dunstrc" << 'EOF'
[global]
    font = FiraCode Nerd Font 9
    frame_width = 2
    separator_height = 1
    follow = mouse
    sticky_history = no
    history_length = 10
    show_indicators = no
    corner_radius = 8

[urgency_low]
    background = "#2e3440"
    foreground = "#d8dee9"
    timeout = 5

[urgency_normal]
    background = "#434c5e"
    foreground = "#eceff4"
    timeout = 8

[urgency_critical]
    background = "#bf616a"
    foreground = "#ffffff"
    timeout = 0
EOF

# === تكوين Alacritty (الطرفية) ===
log "إعداد Alacritty..."

cat > "$ALACRITTY_DIR/alacritty.yml" << 'EOF'
font:
  normal:
    family: "FiraCode Nerd Font"
    style: "Regular"
  size: 10.0

colors:
  primary:
    background: '#2e3440'
    foreground: '#d8dee9'
  cursor:
    text: '#2e3440'
    cursor: '#d8dee9'
  normal:
    black:   '#3b4252'
    red:     '#bf616a'
    green:   '#a3be8c'
    yellow:  '#ebcb8b'
    blue:    '#81a1c1'
    magenta: '#b48ead'
    cyan:    '#88c0d0'
    white:   '#e5e9f0'
  bright:
    black:   '#4c566a'
    red:     '#bf616a'
    green:   '#a3be8c'
    yellow:  '#ebcb8b'
    blue:    '#81a1c1'
    magenta: '#b48ead'
    cyan:    '#88c0d0'
    white:   '#eceff4'

window:
  padding:
    x: 10
    y: 10
EOF

# === خلفية الشاشة ===
log "إعداد خلفية الشاشة الافتراضية..."
feh --bg-scale /usr/share/backgrounds/default.png &

# إذا لم تكن الخلفية موجودة، نُحمّل واحدة جميلة
if [ ! -f /usr/share/backgrounds/default.png ]; then
    sudo mkdir -p /usr/share/backgrounds
    sudo wget -O /usr/share/backgrounds/default.png https://raw.githubusercontent.com/adi1090x/forest-linux/master/wallpaper/forest.png
    feh --bg-scale /usr/share/backgrounds/default.png &
fi

# === Picom (لتأثيرات الشفافية) ===
log "إعداد Picom..."

mkdir -p "$CONFIG_DIR/picom"
cat > "$CONFIG_DIR/picom/picom.conf" << 'EOF'
backend = "glx";
blur-method = "dual_kawase";
blur-strength = 5;
corner-radius = 12;
shadow = true;
shadow-radius = 10;
shadow-offset-x = -10;
shadow-offset-y = -10;
shadow-opacity = 0.25;
fade = true;
fade-delta = 4;
inactive-opacity = 0.9;
frame-opacity = 0.9;
inactive-opacity-override = false;
inactive-dim = 0.1;
wintypes:
{
  tooltip = { fade = true; shadow = false; };
};
EOF

# إضافة تشغيل الخدمات في i3
echo 'exec_always --no-startup-id feh --bg-scale /usr/share/backgrounds/default.png' >> "$I3_DIR/config"
echo 'exec_always --no-startup-id picom --config ~/.config/picom/picom.conf' >> "$I3_DIR/config"
echo 'exec_always --no-startup-id dunst' >> "$I3_DIR/config"

# === الانتهاء ===
log "✅ تم التخصيص بنجاح!"
warn "أعد تشغيل i3 (اضغط \$mod+Shift+r) لرؤية التغييرات."
log "لتحسين التجربة، ننصح بتثبيت 'i3-gaps' بدلاً من 'i3-wm' إذا أردت فواصل بين النوافذ."

# اختياري: تثبيت i3-gaps (يتطلب بناء من المصدر على Debian)
read -p "هل تريد تثبيت i3-gaps لدعم الفراغات بين النوافذ؟ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "جارٍ تثبيت i3-gaps... (قد يستغرق بضع دقائق)"
    sudo apt install -y meson dh-autoreconf libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev xcb libxcb1-dev libxcb1 libxcb-xrm-dev libxcb-cursor-dev libxcb-xinerama0-dev libx11-dev libev-dev libxcb-xkb-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libx11-xcb-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev libxkbcommon-dev libxkbcommon-x11-dev
    cd /tmp
    git clone https://github.com/Airblader/i3 i3-gaps
    cd i3-gaps
    git checkout gaps && git pull
    meson build --prefix /usr
    ninja -C build
    sudo ninja -C build install
    log "✅ تم تثبيت i3-gaps. أعد تشغيل i3 الآن."
fi

log "شكرًا لاستخدامك هذا السكريبت! ✨"
