#!/bin/bash

# i3 + Hyprland-like Transparent Polybar Setup for Debian
# Inspired by Hyprland aesthetics: clean, minimal, transparent, nature-themed
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
    error "لا تقم بتشغيل هذا السكريبت كـ root!"
fi

log "🔄 تحديث النظام وتثبيت الحزم..."
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
log "⚙️  إعداد i3..."

cat > "$I3_DIR/config" << 'EOF'
font pango: FiraCode Nerd Font 10

client.focused          #889988 #889988 #2e3440 #ffffff
client.focused_inactive #4c566a #4c566a #d8dee9 #4c566a
client.unfocused        #434c5e #434c5e #d8dee9 #434c5e
client.urgent           #bf616a #bf616a #ffffff #bf616a

set $mod Mod4

bindsym $mod+Return exec alacritty
bindsym $mod+d exec rofi -show drun
bindsym $mod+Shift+q kill
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'خروج؟' -B 'نعم' 'i3-msg exit'"

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

mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# تشغيل المكونات عند البدء
exec_always --no-startup-id feh --bg-scale ~/.config/backgrounds/hyprland-like.jpg
exec_always --no-startup-id picom --config ~/.config/picom/picom.conf
exec_always --no-startup-id dunst
exec_always --no-startup-id polybar main
EOF

# === Polybar (شفاف مثل Hyprland) ===
log "🎨 إعداد Polybar شفاف بأسلوب Hyprland..."

mkdir -p "$POLYBAR_DIR/scripts"
cat > "$POLYBAR_DIR/scripts/volume.sh" << 'EOF'
#!/bin/sh
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | cut -f2 -d' ' | tr -d '%')
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | cut -d' ' -f2)
if [ "$MUTE" = "yes" ]; then
    echo ""
else
    echo " $VOL%"
fi
EOF

cat > "$POLYBAR_DIR/scripts/brightness.sh" << 'EOF'
#!/bin/sh
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((BRIGHTNESS * 100 / MAX))
echo " $PERCENT%"
EOF

chmod +x "$POLYBAR_DIR/scripts"/*.sh

cat > "$POLYBAR_DIR/config.ini" << 'EOF'
[colors]
background = #2e3440CC   ; شفاف 80%
foreground = #d8dee9
sage = #889988
cyan = #88c0d0
green = #a3be8c
yellow = #ebcb8b
red = #bf616a

[bar/main]
width = 100%
height = 32
radius = 0
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

border-size = 0
padding-left = 2
padding-right = 2
module-margin = 1

font-0 = FiraCode Nerd Font:size=10;2
font-1 = Noto Color Emoji:scale=10;0

modules-left = i3
modules-center = rofi-launcher
modules-right = brightness volume network battery date

tray-position = right
tray-padding = 2

wm-restack = i3

[module/i3]
type = internal/i3
format = <label-state>
index-sort = true
wrapping-scroll = false

label-focused = %name%
label-focused-foreground = ${colors.sage}
label-focused-padding = 2

label-unfocused = %name%
label-unfocused-padding = 2

label-urgent = %name%
label-urgent-background = ${colors.red}
label-urgent-padding = 2

[module/rofi-launcher]
type = custom/text
content = ""
content-foreground = ${colors.cyan}
click-left = rofi -show drun

[module/date]
type = internal/date
interval = 1
time = %H:%M
format = <label>
label = %time%
label-foreground = ${colors.foreground}

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

animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-framerate = 750

[module/volume]
type = custom/script
exec = ~/.config/polybar/scripts/volume.sh
interval = 1
format = <label>
click-left = pactl set-sink-mute @DEFAULT_SINK@ toggle
click-right = pactl set-sink-volume @DEFAULT_SINK@ +5%
scroll-up = pactl set-sink-volume @DEFAULT_SINK@ +2%
scroll-down = pactl set-sink-volume @DEFAULT_SINK@ -2%

[module/brightness]
type = custom/script
exec = ~/.config/polybar/scripts/brightness.sh
interval = 1
format = <label>
click-right = brightnessctl set +5%
scroll-up = brightnessctl set +2%
scroll-down = brightnessctl set -2%

[module/network]
type = internal/network
interface = wlan0
format-connected = <label-connected>
label-connected = 
format-disconnected = <label-disconnected>
label-disconnected = ⚠
EOF

# ضبط واجهة الشبكة تلقائيًا
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
if [ -n "$INTERFACE" ]; then
    sed -i "s/interface = wlan0/interface = $INTERFACE/" "$POLYBAR_DIR/config.ini"
fi

# === Rofi (شفاف، دائري، إطار أخضر زيتي) ===
log "🌀 إعداد Rofi شفاف بإطار أخضر زيتي..."

cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    show-icons: true;
    icon-theme: "Papirus";
    font: "FiraCode Nerd Font 11";
    lines: 10;
    location: 0;
}

* {
    background: rgba(46, 52, 64, 0.88);
    foreground: #d8dee9;
    selected: #889988;
    border: #889988;
    text-color: @foreground;
}

window {
    transparency: "real";
    background-color: @background;
    border: 2px solid @border;
    border-radius: 22px;
    padding: 24px;
    width: 500px;
}

mainbox {
    children: [ inputbar, listview ];
}

inputbar {
    children: [ entry ];
    padding: 12px;
}

entry {
    background-color: rgba(67, 76, 94, 0.7);
    text-color: @foreground;
    caret-color: @selected;
    margin: 8px;
    border-radius: 12px;
    padding: 10px;
}

listview {
    lines: 8;
    columns: 1;
    scrollbar: false;
}

element {
    background-color: transparent;
    text-color: @foreground;
    padding: 10px;
    border-radius: 10px;
}

element selected {
    background-color: @selected;
    text-color: #2e3440;
}
EOF

# === Picom (شفافية متقدمة) ===
log "✨ إعداد Picom للظلال والشفافية..."

cat > "$PICOM_DIR/picom.conf" << 'EOF'
backend = "glx";
vsync = true;
detect-rounded-corners = true;
detect-client-opacity = true;

inactive-opacity = 0.92;
active-opacity = 1.0;
frame-opacity = 0.95;
inactive-dim = 0.1;
blur-method = "dual_kawase";
blur-strength = 8;
blur-background = true;

corner-radius = 16;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];

shadow = true;
shadow-radius = 14;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.28;
shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Dunst'",
  "class_g ?= 'Rofi'"
];

fade = true;
fade-delta = 4;
fading = true;

wintypes:
{
  tooltip = { fade = true; shadow = false; };
  menu = { shadow = false; };
};
EOF

# === خلفية على طراز Hyprland (طبيعة ضبابية/غابة) ===
log "🌄 تنزيل خلفية طبيعية شبيهة بـ Hyprland..."

mkdir -p "$HOME/.config/backgrounds"
BACKGROUND="$HOME/.config/backgrounds/hyprland-like.jpg"

if [ ! -f "$BACKGROUND" ]; then
    # خلفية رسمية من Hyprland أو بديل مشابه
    curl -sL "https://raw.githubusercontent.com/hyprwm/hyprland/main/assets/wall_2.png" -o "$BACKGROUND" || \
    wget -q "https://raw.githubusercontent.com/adi1090x/forest-linux/master/wallpaper/forest.png" -O "$BACKGROUND"
fi

# === الانتهاء ===
log "✅ تم التكوين بنجاح!"
warn "🔄 أعد تشغيل i3 بـ (Mod + Shift + R)"
log "🔹 Polybar شفاف مثل Hyprland"
log "🔹 Rofi: شفاف، دائري، بإطار أخضر زيتي (#889988)"
log "🔹 الخلفية: طبيعية، هادئة، مستوحاة من Hyprland"

# رسالة ترحيب خفيفة
echo -e "\n${GREEN}تم! استمتع ببيئتك الأنيقة 🌿${NC}"
