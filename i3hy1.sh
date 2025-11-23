#!/bin/bash

# i3 + Polybar (بدون bar في i3) + Rofi Theme جميل — على طراز Hyprland
# ✅ بدون كتلة "bar { }" في i3 config
# ✅ Polybar شفاف وأنيق
# ✅ Rofi: شفاف، دائري، بإطار أخضر زيتي
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

log "🔄 تحديث النظام وتثبيت الحزم الأساسية..."
#sudo apt update && sudo apt upgrade -y

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
    libuv1-dev libcairo2-dev libpango1.0-dev
    libxcb1-dev libxcb-randr0-dev libxcb-xinerama0-dev
    libxcb-util-dev libxcb-shape0-dev libxcb-xkb-dev
)

sudo apt install -y "${PKGS[@]}" || error "فشل تثبيت الحزم"

CONFIG_DIR="$HOME/.config"
I3_DIR="$CONFIG_DIR/i3"
POLYBAR_DIR="$CONFIG_DIR/polybar"
ROFI_DIR="$CONFIG_DIR/rofi"
DUNST_DIR="$CONFIG_DIR/dunst"
ALACRITTY_DIR="$CONFIG_DIR/alacritty"
PICOM_DIR="$CONFIG_DIR/picom"
BG_DIR="$CONFIG_DIR/backgrounds"

mkdir -p "$I3_DIR" "$POLYBAR_DIR" "$ROFI_DIR" "$DUNST_DIR" "$ALACRITTY_DIR" "$PICOM_DIR" "$BG_DIR"

# === i3 config — بدون كتلة bar تمامًا ===
log "⚙️  إعداد i3 (بدون أي كتلة bar {...})..."

cat > "$I3_DIR/config" << 'EOF'
font pango: FiraCode Nerd Font 10

# ألوان i3 (نمط Nord هادئ)
client.focused          #889988 #889988 #2e3440 #ffffff
client.focused_inactive #4c566a #4c566a #d8dee9 #4c566a
client.unfocused        #434c5e #434c5e #d8dee9 #434c5e
client.urgent           #bf616a #bf616a #ffffff #bf616a

set $mod Mod4

# تشغيل التطبيقات
bindsym $mod+Return exec alacritty
bindsym $mod+d exec rofi -show drun
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'خروج؟' -B 'نعم' 'i3-msg exit'"

# التنقل
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# تحريك النوافذ
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# أوامر إضافية
bindsym $mod+f fullscreen toggle
bindsym $mod+b split h
bindsym $mod+v split v

mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# ⚠️ لا وجود لـ "bar { }" هنا — Polybar يُدار خارجيًا
exec_always --no-startup-id feh --bg-scale ~/.config/backgrounds/hyprland-bg.jpg
exec_always --no-startup-id picom --config ~/.config/picom/picom.conf
exec_always --no-startup-id dunst
exec_always --no-startup-id polybar main
EOF

# === Polybar (شفاف، عصري، بدون تكرار مع i3) ===
log "🎨 إعداد Polybar شفاف على طراز Hyprland..."

mkdir -p "$POLYBAR_DIR/scripts"

# سكريبت الصوت
cat > "$POLYBAR_DIR/scripts/volume.sh" << 'EOF'
#!/bin/sh
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | tr -d '%')
if [ "$MUTE" = "yes" ]; then
    echo " MUTE"
else
    echo " $VOL%"
fi
EOF

# سكريبت السطوع
cat > "$POLYBAR_DIR/scripts/brightness.sh" << 'EOF'
#!/bin/sh
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))
echo " $PERCENT%"
EOF

chmod +x "$POLYBAR_DIR/scripts"/*.sh

# ملف التكوين الرئيسي لـ Polybar
cat > "$POLYBAR_DIR/config.ini" << 'EOF'
[colors]
bg = #2e3440DD   ; خلفية شفافة (85% تعتيم)
fg = #d8dee9
sage = #889988
cyan = #88c0d0
green = #a3be8c
red = #bf616a

[bar/main]
width = 100%
height = 30
radius = 0
fixed-center = true

background = ${colors.bg}
foreground = ${colors.fg}

border-size = 0
padding-left = 2
padding-right = 2
module-margin = 1

font-0 = FiraCode Nerd Font:size=10;2
font-1 = Noto Color Emoji:scale=10;0

modules-left = i3
modules-center = rofi-btn
modules-right = brightness volume network battery time

tray-position = right
tray-padding = 2
wm-restack = i3

[module/i3]
type = internal/i3
format = <label-state>
index-sort = true

label-focused = %name%
label-focused-foreground = ${colors.sage}
label-focused-padding = 2

label-unfocused = %name%
label-unfocused-padding = 2

label-urgent = %name%
label-urgent-background = ${colors.red}
label-urgent-padding = 2

[module/rofi-btn]
type = custom/text
content = ""
content-foreground = ${colors.cyan}
click-left = rofi -show drun

[module/time]
type = internal/date
interval = 1
time = %H:%M
format = <label>
label = %time%

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
format-discharging = <ramp-capacity> <label-discharging>
format-charging = <animation-charging> <label-charging>
format-full = <label-full>
label-discharging = %percentage%%
label-charging = %percentage%%
label-full = 

ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-3 = 
ramp-capacity-4 = 

animation-charging-framerate = 750

[module/volume]
type = custom/script
exec = ~/.config/polybar/scripts/volume.sh
interval = 1
format = <label>

[module/brightness]
type = custom/script
exec = ~/.config/polybar/scripts/brightness.sh
interval = 1
format = <label>

[module/network]
type = internal/network
interface = auto
format-connected = <label-connected>
label-connected = 
format-disconnected = <label-disconnected>
label-disconnected = ⚠
EOF

# === Rofi Theme (جميل، شفاف، دائري، بإطار أخضر زيتي) ===
log "🌀 إعداد ثيم Rofi فخم وشفاف..."

cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    show-icons: true;
    icon-theme: "Papirus";
    font: "FiraCode Nerd Font 11";
    lines: 12;
    columns: 3;
    location: 0;  /* منتصف الشاشة */
}

* {
    background: rgba(46, 52, 64, 0.88);
    background-alt: rgba(67, 76, 94, 0.85);
    foreground: #d8dee9;
    selected: #889988;
    border: #889988;
    text-color: @foreground;
}

window {
    transparency: "real";
    background-color: @background;
    border: 2px solid @border;
    border-radius: 24px;
    padding: 28px;
    margin: 0;
    width: 520px;
}

mainbox {
    children: [ inputbar, listview ];
}

inputbar {
    children: [ entry ];
    padding: 14px;
}

entry {
    background-color: rgba(59, 66, 82, 0.7);
    text-color: @foreground;
    caret-color: @selected;
    margin: 10px;
    border-radius: 14px;
    padding: 12px;
}

listview {
    lines: 10;
    columns: 1;
    scrollbar: false;
}

element {
    background-color: transparent;
    text-color: @foreground;
    padding: 12px;
    border-radius: 12px;
}

element selected {
    background-color: @selected;
    text-color: #2e3440;
    border-radius: 12px;
}
EOF

# === Picom (للشفافية والظلال الناعمة) ===
log "✨ إعداد Picom لتأثيرات احترافية..."

cat > "$PICOM_DIR/picom.conf" << 'EOF'
backend = "glx";
vsync = true;
detect-rounded-corners = true;
detect-client-opacity = true;

inactive-opacity = 0.9;
active-opacity = 1.0;
frame-opacity = 0.95;
blur-method = "dual_kawase";
blur-strength = 8;
blur-background = true;

corner-radius = 18;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "class_g = 'Polybar'"
];

shadow = true;
shadow-radius = 16;
shadow-offset-x = -8;
shadow-offset-y = -8;
shadow-opacity = 0.3;
shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Dunst'",
  "class_g ?= 'Rofi'"
];

fade = true;
fade-delta = 3;
fading = true;
EOF

# === خلفية على طراز Hyprland ===
log "🖼️  تنزيل خلفية Hyprland الرسمية..."

BG_PATH="$BG_DIR/hyprland-bg.jpg"
if [ ! -f "$BG_PATH" ]; then
    curl -sL "https://raw.githubusercontent.com/hyprwm/hyprland/main/assets/wall_2.png" -o "$BG_PATH" || \
    wget -q "https://raw.githubusercontent.com/adi1090x/forest-linux/master/wallpaper/dark-forest.png" -O "$BG_PATH"
fi

# === الانتهاء ===
log "✅ التهيئة اكتملت بنجاح!"
warn "🔄 أعد تشغيل i3 الآن بـ (Mod + Shift + R)"
log "• Polybar شفاف بدون bar في i3"
log "• Rofi: منتصف الشاشة، شفاف، بإطار أخضر زيتي"
log "• الخلفية: طبيعية وهادئة على طراز Hyprland"

echo -e "\n${GREEN}استمتع ببيئتك العصرية! 🌿${NC}"
