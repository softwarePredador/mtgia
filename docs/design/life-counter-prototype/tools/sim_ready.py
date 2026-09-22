"""Exit 0 once the simulator shows the table (coloured panels) instead of the dark splash."""
import subprocess, sys, tempfile, os
from PIL import Image
p = os.path.join(tempfile.gettempdir(), 'mesa_ready.png')
subprocess.run(['xcrun', 'simctl', 'io', 'booted', 'screenshot', p], capture_output=True)
im = Image.open(p).convert('RGB'); w, h = im.size
pts = [(w * .25, h * .2), (w * .75, h * .2), (w * .25, h * .8), (w * .75, h * .8)]
lit = sum(1 for x, y in pts if sum(im.getpixel((int(x), int(y)))) > 140)
sys.exit(0 if lit >= 3 else 1)
