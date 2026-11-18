import os, sys
from pathlib import Path
from PIL import Image

def upscale_image(input_path, output_path, scale=2, target_ratio=(16,9), bg_color=(0,0,0)):
    img = Image.open(input_path)
    # Upscale
    new_width = img.width * scale
    new_height = img.height * scale
    img_resized = img.resize((new_width, new_height), Image.LANCZOS)
    # Determine target canvas size maintaining target_ratio and covering resized image
    # Compute canvas height based on width to match ratio, then ensure both dimensions >= resized dimensions
    target_w = new_width
    target_h = int(target_w * target_ratio[1] / target_ratio[0])
    if target_h < new_height:
        target_h = new_height
        target_w = int(target_h * target_ratio[0] / target_ratio[1])
    canvas = Image.new('RGB', (target_w, target_h), bg_color)
    # Center resized image
    offset_x = (target_w - new_width) // 2
    offset_y = (target_h - new_height) // 2
    canvas.paste(img_resized, (offset_x, offset_y))
    canvas.save(output_path)
    print(f"Saved upscaled image to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python upscale_image.py <input_path> <output_path>")
        sys.exit(1)
    infile = Path(sys.argv[1])
    outfile = Path(sys.argv[2])
    upscale_image(infile, outfile)
