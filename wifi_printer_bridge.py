# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "pillow",
#     "arabic-reshaper",
#     "python-bidi",
# ]
# ///
import socket
import subprocess
import tempfile
import os
import sys
import re
import datetime
import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFont

PRINTER_URI = "usb://Xprinter/XP-365B?location=3140000"
CUPS_USB_BACKEND = "/usr/libexec/cups/backend/usb"
PORT = 9100
LOG_FILE = "/tmp/printer_bridge.log"
WIDTH_DOTS = 576  # 72mm printable width at 203 DPI (8 dots/mm)
WIDTH_BYTES = WIDTH_DOTS // 8  # 72 bytes

def log(msg):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{now}] {msg}\n"
    with open(LOG_FILE, "a") as f:
        f.write(line)
    print(line, end="", flush=True)

def bidi_text(text: str) -> str:
    if not text:
        return ""
    has_arabic = any('\u0600' <= c <= '\u06ff' or '\u0750' <= c <= '\u077f' for c in text)
    if has_arabic:
        try:
            return get_display(arabic_reshaper.reshape(text))
        except Exception:
            return text
    return text

def render_receipt_to_bitmap(raw_data: bytes) -> tuple[bytes, int]:
    text = raw_data.decode('utf-8', errors='ignore')
    
    # Filter lines
    lines = []
    for raw_l in text.split('\n'):
        l = raw_l.strip()
        if not l or l.startswith('SIZE ') or l.startswith('GAP ') or l.startswith('DIRECTION ') or l == 'CLS' or l.startswith('PRINT '):
            continue
        m = re.search(r'TEXT\s+\d+,\d+,"[^"]+",\d+,\d+,\d+,"(.*)"', l)
        if m:
            l = m.group(1).replace('\\"', '"')
        
        clean = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', l).strip()
        clean = re.sub(r'^[@!\x00-\x20]+', '', clean).strip()
        if clean and clean not in ['@', 'VA']:
            lines.append(clean)

    if not lines:
        lines = ["CABRA BEAN CAFE", "TABLE BILL", "TEST OK"]

    font_path = "/System/Library/Fonts/Supplemental/Arial.ttf"
    if not os.path.exists(font_path):
        font_path = "/System/Library/Fonts/GeezaPro.ttc"
        
    try:
        font_title = ImageFont.truetype(font_path, 32)
        font_header = ImageFont.truetype(font_path, 25)
        font_body = ImageFont.truetype(font_path, 21)
        font_bold = ImageFont.truetype(font_path, 23)
    except Exception:
        font_title = ImageFont.load_default()
        font_header = ImageFont.load_default()
        font_body = ImageFont.load_default()
        font_bold = ImageFont.load_default()

    y = 20
    elements = []

    for l in lines:
        if l.startswith('===') or l.startswith('---'):
            elements.append(('line', y))
            y += 14
        elif any(k in l.upper() for k in ['CABRA BEAN', 'كابرا بين']):
            elements.append(('center', bidi_text(l), font_title, y))
            y += 40
        elif any(k in l.upper() for k in ['TOTAL', 'المجموع', 'TABLE BILL', 'فاتورة طاولة', 'TEST PRINT', 'فحص اتصال']):
            elements.append(('center', bidi_text(l), font_header, y))
            y += 34
        elif any(k in l.upper() for k in ['TABLE:', 'طاولة:', 'WAITER:', 'الويتر:', 'نادل:']):
            elements.append(('right', bidi_text(l), font_bold, y))
            y += 28
        else:
            elements.append(('right', bidi_text(l), font_body, y))
            y += 26

    total_height_dots = y + 40
    img = Image.new('1', (WIDTH_DOTS, total_height_dots), color=1) # 1 = white background
    draw = ImageDraw.Draw(img)

    for elem in elements:
        kind = elem[0]
        if kind == 'line':
            py = elem[1]
            draw.line([(20, py), (WIDTH_DOTS - 20, py)], fill=0, width=2)
        elif kind == 'center':
            _, t, f, py = elem
            draw.text((WIDTH_DOTS // 2, py), t, font=f, fill=0, anchor='mt')
        elif kind == 'right':
            _, t, f, py = elem
            has_ar = any('\u0600' <= c <= '\u06ff' for c in t)
            if has_ar:
                draw.text((WIDTH_DOTS - 25, py), t, font=f, fill=0, anchor='ra')
            else:
                draw.text((25, py), t, font=f, fill=0, anchor='la')

    raw_bytes = bytearray()
    for row in range(total_height_dots):
        for col_byte in range(WIDTH_BYTES):
            b = 0
            for bit in range(8):
                px = img.getpixel((col_byte * 8 + bit, row))
                # Printer polarity: 0 burns black ink, 1 leaves white paper
                if px != 0:  # White background
                    b |= (1 << (7 - bit))
            raw_bytes.append(b)

    return bytes(raw_bytes), total_height_dots

def forward_to_usb(data: bytes, client_ip: str):
    log(f"Processing {len(data)} bytes from {client_ip}...")
    
    try:
        raster_bytes, height_dots = render_receipt_to_bitmap(data)
        height_mm = max(35, int((height_dots + 40) / 8))

        header = f"SIZE 75 mm, {height_mm} mm\nGAP 0,0\nDIRECTION 1\nCLS\nBITMAP 0,10,{WIDTH_BYTES},{height_dots},0,".encode('ascii')
        footer = b"\nPRINT 1,1\n"
        tspl_payload = header + raster_bytes + footer

        with tempfile.NamedTemporaryFile(delete=False, suffix=".bin") as tmp:
            tmp.write(tspl_payload)
            tmp_path = tmp.name

        env = os.environ.copy()
        env["DEVICE_URI"] = PRINTER_URI
        log(f"Sending {len(tspl_payload)} bytes Arabic bitmap to printer via CUPS...")
        res = subprocess.run(
            [CUPS_USB_BACKEND, "103", "wifi_arabic", "Arabic Table Bill", "1", "", tmp_path],
            env=env,
            capture_output=True,
            text=True,
            timeout=15
        )
        log(f"CUPS return code: {res.returncode}")
        try:
            os.remove(tmp_path)
        except OSError:
            pass
    except Exception as e:
        log(f"ERROR in rasterization / printing: {e}")

def main():
    log("Starting Arabic Bitmap Wi-Fi Printer Bridge on port 9100...")
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    try:
        server.bind(("0.0.0.0", PORT))
    except Exception as e:
        log(f"Failed to bind port {PORT}: {e}")
        sys.exit(1)

    server.listen(10)
    log(f"Ready on 0.0.0.0:{PORT} with full Arabic rendering!")

    while True:
        try:
            client, addr = server.accept()
            client_ip = addr[0]
            log(f"Connection from {client_ip}")
            client.settimeout(4.0)
            chunks = []
            while True:
                try:
                    chunk = client.recv(4096)
                    if not chunk:
                        break
                    chunks.append(chunk)
                except socket.timeout:
                    break
                except Exception:
                    break
            client.close()
            payload = b"".join(chunks)
            if payload:
                forward_to_usb(payload, client_ip)
        except Exception as e:
            log(f"Server loop error: {e}")

if __name__ == "__main__":
    main()
