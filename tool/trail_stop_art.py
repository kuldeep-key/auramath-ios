"""DRAFT trail stop art (REW-04, FL-51): simple flat shapes in the app's
palette, drawn at 4x and scaled down, 96 px square (the stop shows them at
34 pt). Design replaces the files under the same names."""
import sys
from PIL import Image, ImageDraw

# run from the app root: python3 tool/trail_stop_art.py
out = sys.argv[1] if len(sys.argv) > 1 else "assets/images"
S = 96 * 4
NAVY, BLUE, GREEN, YELLOW, LIP, CORAL = "#0F2A73", "#2F6BFF", "#22A06B", "#FFC531", "#E5A100", "#FF7A59"
W = 6 * 4  # outline

def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))

def save(img, name):
    img.resize((96, 96), Image.LANCZOS).save(f"{out}/trail_stop_{name}.png")

def rr(d, box, fill, r=24):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=NAVY, width=W)

# add: two blocks and a plus
img = canvas(); d = ImageDraw.Draw(img)
rr(d, (40, 200, 160, 320), YELLOW); rr(d, (224, 200, 344, 320), YELLOW)
d.rounded_rectangle((152, 76, 232, 156), radius=10, fill=BLUE)
d.rectangle((176, 40, 208, 192), fill=BLUE); d.rectangle((116, 100, 268, 132), fill=BLUE)
save(img, "add_big")

# take away: a block, one crossed out, a minus
img = canvas(); d = ImageDraw.Draw(img)
rr(d, (40, 200, 160, 320), YELLOW); rr(d, (224, 200, 344, 320), "#FFF3CC")
d.line((236, 212, 332, 308), fill=NAVY, width=W); d.line((332, 212, 236, 308), fill=NAVY, width=W)
d.rounded_rectangle((116, 96, 268, 136), radius=12, fill=CORAL)
save(img, "take_away_big")

# trees: a tall and a short tree (comparing)
img = canvas(); d = ImageDraw.Draw(img)
d.rectangle((104, 250, 136, 340), fill="#8B5A2B"); d.ellipse((50, 40, 190, 270), fill=GREEN, outline=NAVY, width=W)
d.rectangle((258, 280, 286, 340), fill="#8B5A2B"); d.ellipse((210, 150, 334, 300), fill=GREEN, outline=NAVY, width=W)
d.line((30, 344, 354, 344), fill=NAVY, width=W)
save(img, "trees")

# tricky words: two arrows swapping
img = canvas(); d = ImageDraw.Draw(img)
d.rectangle((60, 120, 280, 160), fill=BLUE); d.polygon([(280, 80), (350, 140), (280, 200)], fill=BLUE)
d.rectangle((104, 228, 324, 268), fill=CORAL); d.polygon([(104, 188), (34, 248), (104, 308)], fill=CORAL)
save(img, "tricky_words")

# total and difference: two bars, the gap marked
img = canvas(); d = ImageDraw.Draw(img)
rr(d, (40, 90, 344, 170), BLUE, 16); rr(d, (40, 214, 230, 294), YELLOW, 16)
d.rectangle((246, 222, 344, 286), outline=CORAL, width=W)
save(img, "total_and_difference")
