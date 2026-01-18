from PIL import Image
import os
import sys

def process_image(im, low_thr, high_thr, wipe_rgb_low, clamp_alpha, borderfix, tile_size):
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    changed = 0

    # 1) wipe RGB on low alpha + 2) clamp alpha near 0 / near 255
    if wipe_rgb_low or clamp_alpha:
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]

                # clamp alpha
                if clamp_alpha:
                    if a <= low_thr:
                        if a != 0:
                            a = 0
                            changed += 1
                    elif a >= high_thr:
                        if a != 255:
                            a = 255
                            changed += 1

                # wipe RGB where (now) low alpha
                if wipe_rgb_low and a <= low_thr and (r != 0 or g != 0 or b != 0):
                    px[x, y] = (0, 0, 0, a)
                    changed += 1
                else:
                    # alpha만 바뀌었을 수 있으니 기록
                    if clamp_alpha:
                        px[x, y] = (r, g, b, a)

    # 3) border fix (optional)
    border_changed = 0
    if borderfix and tile_size > 0 and w >= tile_size and h >= tile_size:
        tiles_x = w // tile_size
        tiles_y = h // tile_size

        for ty in range(tiles_y):
            for tx in range(tiles_x):
                x0 = tx * tile_size
                y0 = ty * tile_size

                # top/bottom
                for x in range(x0, x0 + tile_size):
                    r, g, b, a = px[x, y0]
                    if a <= low_thr:
                        rr, gg, bb, aa = px[x, y0 + 1]
                        px[x, y0] = (rr, gg, bb, 255)
                        border_changed += 1

                    r, g, b, a = px[x, y0 + tile_size - 1]
                    if a <= low_thr:
                        rr, gg, bb, aa = px[x, y0 + tile_size - 2]
                        px[x, y0 + tile_size - 1] = (rr, gg, bb, 255)
                        border_changed += 1

                # left/right
                for y in range(y0, y0 + tile_size):
                    r, g, b, a = px[x0, y]
                    if a <= low_thr:
                        rr, gg, bb, aa = px[x0 + 1, y]
                        px[x0, y] = (rr, gg, bb, 255)
                        border_changed += 1

                    r, g, b, a = px[x0 + tile_size - 1, y]
                    if a <= low_thr:
                        rr, gg, bb, aa = px[x0 + tile_size - 2, y]
                        px[x0 + tile_size - 1, y] = (rr, gg, bb, 255)
                        border_changed += 1

    return im, changed, border_changed

def main():
    if len(sys.argv) < 2:
        print("usage: py batch_alpha_clean.py <dir> [low_thr] [high_thr] [tile_size] [mode]")
        print("mode: basic | border")
        print("example: py batch_alpha_clean.py . 4 252 32 basic")
        print("example: py batch_alpha_clean.py . 4 252 32 border")
        sys.exit(2)

    root = sys.argv[1]
    low_thr = int(sys.argv[2]) if len(sys.argv) >= 3 else 4
    high_thr = int(sys.argv[3]) if len(sys.argv) >= 4 else 252
    tile_size = int(sys.argv[4]) if len(sys.argv) >= 5 else 32
    mode = sys.argv[5].lower() if len(sys.argv) >= 6 else "basic"

    wipe_rgb_low = True
    clamp_alpha = True
    borderfix = (mode == "border")

    out_dir = os.path.join(root, "out_png")
    os.makedirs(out_dir, exist_ok=True)

    total_files = 0
    for name in sorted(os.listdir(root)):
        if not name.lower().endswith(".png"):
            continue
        # out_dir 내부 결과물 재처리 방지
        if name.startswith("out_"):
            continue

        in_path = os.path.join(root, name)
        out_path = os.path.join(out_dir, name)

        try:
            im = Image.open(in_path)
        except Exception as e:
            print("skip (open failed):", name, str(e))
            continue

        out, changed, border_changed = process_image(
            im,
            low_thr=low_thr,
            high_thr=high_thr,
            wipe_rgb_low=wipe_rgb_low,
            clamp_alpha=clamp_alpha,
            borderfix=borderfix,
            tile_size=tile_size
        )

        out.save(out_path)
        total_files += 1
        print("ok:", name, "-> out_png/", "changed:", changed, "border_changed:", border_changed)

    print("done. processed:", total_files, "files. out_dir:", out_dir)

if __name__ == "__main__":
    main()
