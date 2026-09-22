#!/usr/bin/env python3
"""View-coords -> device points.
_view.png is the simulator shot rotated 90 CCW (readable landscape) and scaled to 1000px wide.
Portrait device: 402x874 pt @3x = 1206x2622 px.  Rotated: 2622x1206 px.  View scale = 1000/2622.
Rotated pixel (nx,ny) came from portrait pixel x = 1205-ny, y = nx.
"""
import sys
K = 2622 / 1000.0
for arg in sys.argv[1:]:
    vx, vy = [float(v) for v in arg.split(',')]
    nx, ny = vx * K, vy * K
    px, py = (1205 - ny) / 3.0, nx / 3.0
    print(f"view {vx:.0f},{vy:.0f}  ->  device {px:.0f},{py:.0f}")
