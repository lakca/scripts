from PIL import Image
from sys import argv


def main(file):
    with Image.open(file) as pic:
        pic.image.show()
        picRgb = pic.convert(mode="RGB")  # convert RGBA to RGB
        picRgb.image.show()
        pic8 = pic.quantize(colors=256, method=Image.MAXCOVERAGE)
        pic8.image.show()


if __name__ == "__main__":
    file = argv[1]
    main(file)
