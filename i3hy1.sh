#!/bin/bash

# i3 + Polybar + Rofi (Sage Green Transparent Theme) Setup for Debian
# Inspired by Hyprland aesthetics
# Last updated: 2025-11-23

set -e

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ "$EUID" -eq 0 ]; then
    error "لا تشغل هذا السكريبت كـ root!"
fi

log "التحديث الأولي للنظام..."
#sudo apt update && sudo apt upgrade -y

# تثبيت الحزم المطلوبة
log "تثبيت الحزم الأساسية..."
PKGS=(
    i3-wm
    polybar
    rofi
    feh
    picom
    dunst
    alacritty
    fonts-firacode
    fonts-font-awesome
    fonts-noto-color-emoji
    pulseaudio-utils
    brightnessctl
    acpi
    network-manager-gnome
    git
    build-essential
    libuv1-dev
    libcairo2-dev
    libpango1.0-dev
    libxcb1-dev
    libxcb-randr0-dev
    libxcb-xinerama0-dev
    libxcb-util-dev
    libxcb-shape0-dev
    libxcb-xkb-dev
)

sudo apt install -y "${PKGS[@]}" || error "فشل تثبيت الحزم"

CONFIG_DIR="$HOME/.config"
I3_DIR="$CONFIG_DIR/i3"
POLYBAR_DIR="$CONFIG_DIR/polybar"
ROFI_DIR="$CONFIG_DIR/rofi"
DUNST_DIR="$CONFIG_DIR/dunst"
ALACRITTY_DIR="$CONFIG_DIR/alacritty"
PICOM_DIR="$CONFIG_DIR/picom"

mkdir -p "$I3_DIR" "$POLYBAR_DIR" "$ROFI_DIR" "$DUNST_DIR" "$ALACRITTY_DIR" "$PICOM_DIR"

# === i3 config ===
log "إعداد i3 مع Polybar..."

cat > "$I3_DIR/config" << 'EOF'
font pango: FiraCode Nerd Font 10

# الألوان (نمط أنيق)
client.focused          #889988 #889988 #2e3440 #ffffff
client.focused_inactive #4c566a #4c566a #eceff4 #4c566a
client.unfocused        #434c5e #434c5e #d8dee9 #434c5e
client.urgent           #bf616a #bf616a #ffffff #bf616a

set $mod Mod4

bindsym $mod+Return exec alacritty
bindsym $mod+d exec rofi -show drun
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'خروج؟' -B 'نعم' 'i3-msg exit'"

# التنقل والتحكم
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

bindsym $mod+f fullscreen toggle
bindsym $mod+b split h
bindsym $mod+v split v

# وضع التحجيم
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# تشغيل Polybar تلقائيًا
exec_always --no-startup-id polybar main
exec_always --no-startup-id picom --config ~/.config/picom/picom.conf
exec_always --no-startup-id dunst
exec_always --no-startup-id feh --bg-scale /usr/share/backgrounds/forest.png
EOF

# === Polybar Config ===
log "إعداد Polybar..."

cat > "$POLYBAR_DIR/config.ini" << 'EOF'
[colors]
background = ${xrdb:color0:#2e3440}
foreground = ${xrdb:color7:#d8dee9}
sage = #889988
red = #bf616a
green = #a3be8c
yellow = #ebcb8b
blue = #81a1c1

[bar/main]
width = 100%
height = 30
radius = 0
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 2
line-color = ${colors.sage}

border-size = 0
padding-left = 0
padding-right = 0

module-margin-left = 1
module-margin-right = 1

font-0 = FiraCode Nerd Font:style=Regular:size=10;2
font-1 = Noto Color Emoji:scale=10;0

modules-left = i3
modules-center = rofi-launcher
modules-right = brightness volume network battery date

tray-position = right
tray-padding = 2
tray-detached = false

wm-restack = i3
override-redirect = false

[module/i3]
type = internal/i3
format = <label-state>
index-sort = true
wrapping-scroll = false

label-focused = %name%
label-focused-background = ${colors.sage}
label-focused-underline = ${colors.sage}
label-focused-padding = 2

label-unfocused = %name%
label-unfocused-padding = 2

label-urgent = %name%
label-urgent-background = ${colors.red}
label-urgent-padding = 2

[module/rofi-launcher]
type = custom/text
content = ""
content-foreground = ${colors.sage}
content-background = ${colors.background}
click-left = rofi -show drun

[module/date]
type = internal/date
interval = 1
date = %a %d %b
date-alt = %A, %d %B %Y
time = %H:%M
time-alt = %H:%M:%S
format = <label>
label = %date% %time%
label-foreground = ${colors.foreground}

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
full-at = 99
format-charging = <animation-charging> <label-charging>
format-discharging = <ramp-capacity> <label-discharging>
format-full = <label-full>
label-charging = %percentage%%
label-discharging = %percentage%%
label-full = 

ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-3 = 
ramp-capacity-4 = 

animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-framerate = 750

[module/volume]
type = internal/pulseaudio
format-volume = <ramp-volume> <label-volume>
label-volume = %percentage%%
format-muted = <label-muted>
label-muted =  MUTE

ramp-volume-0 = 
ramp-volume-1 = 
ramp-volume-2 = 

[module/brightness]
type = internal/backlight
card = intel_backlight
enable-scroll = true
format = <ramp> <label>
label = %percentage%%
ramp-0 = 
ramp-1 = 
ramp-2 = 
ramp-3 = 
ramp-4 = 

[module/network]
type = internal/network
interface = wlan0
interface-type = wireless
format-connected = <label-connected>
label-connected =  %local_ip%
format-disconnected = <label-disconnected>
label-disconnected = ⚠ Disconnected
EOF

# استخدام الواجهة الصحيحة تلقائيًا
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
if [ -n "$INTERFACE" ]; then
    sed -i "s/interface = wlan0/interface = $INTERFACE/" "$POLYBAR_DIR/config.ini"
fi

# === Rofi Theme (شفاف + إطار أخضر زيتي) ===
log "إعداد Rofi بتصميم شفاف مع إطار أخضر زيتي..."

cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    show-icons: true;
    icon-theme: "Papirus";
    font: "FiraCode Nerd Font 11";
    lines: 10;
    columns: 3;
    width: 50;
    location: 0;  /* center */
}

* {
    background: rgba(46, 52, 64, 0.85);
    background-alt: rgba(67, 76, 94, 0.85);
    foreground: #d8dee9;
    selected: #889988;
    border: #889988;
    border-radius: 20px;
    text-color: @foreground;
}

window {
    transparency: "real";
    background-color: @background;
    border: 2px solid @border;
    border-radius: 20px;
    padding: 20px;
    width: 400px;
}

mainbox {
    children: [ mode-switcher, inputbar, listview ];
}

inputbar {
    children: [ prompt, entry ];
    padding: 10px;
}

entry {
    background-color: @background-alt;
    text-color: @foreground;
    caret-color: @selected;
    margin: 5px;
    border-radius: 10px;
    padding: 8px;
}

listview {
    lines: 8;
    columns: 1;
    scrollbar: false;
}

element {
    background-color: transparent;
    text-color: @foreground;
    padding: 8px;
    border-radius: 8px;
}

element selected {
    background-color: @selected;
    text-color: @background;
}
EOF

# === Picom (للشفافية والظلال) ===
log "إعداد Picom للشفافية..."

cat > "$PICOM_DIR/picom.conf" << 'EOF'
backend = "glx";
vsync = true;
refresh-rate = 60;
detect-rounded-corners = true;
detect-client-opacity = true;

# تأثيرات الشفافية
inactive-opacity = 0.9;
active-opacity = 1.0;
frame-opacity = 0.9;
inactive-dim = 0.1;
blur-method = "dual_kawase";
blur-strength = 6;
blur-background = true;
blur-background-frame = false;

# الزوايا المستديرة
corner-radius = 14;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];

# الظلال
shadow = true;
shadow-radius = 12;
shadow-offset-x = -8;
shadow-offset-y = -8;
shadow-opacity = 0.25;
shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Dunst'",
  "class_g ?= 'Rofi'"
];

# Rofi خاص (بدون ظل، شفافية كاملة)
wintypes:
{
  tooltip = { fade = true; shadow = false; };
  menu = { shadow = false; };
  dropdown_menu = { shadow = false; };
};
EOF

# === خلفية شاشة جميلة ===
log "تنزيل خلفية حرجية (Forest)..."
sudo mkdir -p /usr/share/backgrounds
sudo wget -O /usr/share/backgrounds/forest.png https://raw.githubusercontent.com/adi1090x/forest-linux/master/wallpaper/forest.png

# === تثبيت سكربتات مساعدة (اختياري) ===
# يمكننا إضافة سكربتات للتحكم بالصوت/السطوع لاحقًا إذا طلبت

log "✅ تم التكوين بنجاح!"
warn "أعد تشغيل i3 (Mod+Shift+r) لرؤية التغييرات."
log "• اضغط على أيقونة '' في منتصف شريط Polybar لفتح Rofi"
log "• Rofi سيكون شفافًا مع إطار أخضر زيتي وموقع مركزي"

# نصيحة أخيرة
warn "إذا لم يظهر Rofi بشكل شفاف، تأكد من أن picom قيد التشغيل."
