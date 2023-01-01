#!/usr/bin/env python3

import yaml
import os, sys, getopt
import xml.etree.ElementTree as Et


class Rect:
    x = 0
    y = 0
    width = 0
    height = 0

    def __init__(self, x, y, width, height):
        self.x = float(x) - 0.5
        self.y = float(y) - 0.5
        self.width = float(width) + 1
        self.height = float(height) + 1


class Ellipse:
    x = 0
    y = 0
    width = 0
    height = 0

    def __init__(self, x, y, width, height):
        self.x = float(x) - float(width) - 1.6
        self.y = float(y) - float(height) - 1.8
        self.width = (float(width) + 2) * 2
        self.height = (float(height) + 2) * 2


def help():
    """
example:
    # python ./svg_to_position.py -f apm32f103zet6.svg -o apm32f103zet6.yml
    """
    print("usage: " + os.path.basename(__file__) + " [<options>] ")
    print("")
    print("    -h, --help       print this help")
    print("    -f, --file       clock svg file")
    print("    -o, --output     output file")


def parse_svg(file):
    rects = []
    ellipses = []
    width = 0
    height = 0

    svg_tree = Et.parse(file)
    svg_root = svg_tree.getroot()
    for item in svg_root.iter():

        if item.tag.lower().endswith("svg"):
            # <svg version="1.1" width="1603px" height="903px" viewBox="-0.5 -0.5 1603 903" />
            width = float(item.attrib["width"].replace("px", ""))
            height = float(item.attrib["height"].replace("px", ""))
        # <rect x="521" y="221" width="55" height="30" rx="4.5" ry="4.5" fill="#94d2ef" stroke="#000000" stroke-width="1" pointer-events="none" />
        elif item.tag.lower().endswith("rect") and "rx" not in item.attrib.keys() and "ry" not in item.attrib.keys():
            # stroke-width defaults to 1. We only match rectangles with a line width of 1
            if "stroke-width" not in item.attrib.keys():
                rects.append(Rect(item.attrib["x"], item.attrib["y"], item.attrib["width"], item.attrib["height"]))
            else:
                if item.attrib["stroke-width"] == "1":
                    rects.append(Rect(item.attrib["x"], item.attrib["y"], item.attrib["width"], item.attrib["height"]))
        # <ellipse cx="436.06" cy="96" rx="5" ry="5" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="none" />
        elif item.tag.lower().endswith("ellipse"):
            if item.attrib["rx"] == item.attrib["ry"]:
                if float(item.attrib["rx"]) >= 5:
                    ellipses.append(Ellipse(item.attrib["cx"], item.attrib["cy"], item.attrib["rx"], item.attrib["ry"]))
        # Arrange controls by coordinates
        rects.sort(key=lambda x: (x.x, x.y))
        ellipses.sort(key=lambda x: (x.x, x.y))
    return width, height, rects, ellipses


controls = {}
yml = []


def main(file, output):
    width, height, rects, ellipses = parse_svg(file)
    yml.append("Width: " + str(width))
    yml.append("Height: " + str(height))
    if os.path.exists(output):
        string = ""
        with open(output, "r") as fp:
            string = fp.read()
        config = yaml.load(string, Loader=yaml.FullLoader)
        if "Controls" in config.keys():
            controls = config["Controls"]
    if (len(controls) > 0):
        yml.append(yaml.dump(controls, sort_keys=False).replace("'", "").strip())
    i = 0
    yml.append("Rects:")
    for rect in rects:
        i += 1
        yml.append("  {id}: {{ X: {x}, Y: {y}, Width: {width}, Height: {height} }}".format(id=i,
                                                                                           x=rect.x,
                                                                                           y=rect.y,
                                                                                           width=rect.width,
                                                                                           height=rect.height))
    yml.append("Ellipses:")
    for ellipse in ellipses:
        i += 1
        yml.append("  {id}: {{ X: {x}, Y: {y}, Width: {width}, Height: {height} }}".format(id=i,
                                                                                           x=ellipse.x,
                                                                                           y=ellipse.y,
                                                                                           width=ellipse.width,
                                                                                           height=ellipse.height))
    # with open(output, "w", encoding="utf-8") as fp:
    # fp.write("\n".join(yml))
    print("\n".join(yml))


if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hf:o:", ["help", "file=", "output="])
    except getopt.GetoptError:
        help()
        sys.exit(2)

    file = ""
    output = ""
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit()
        elif opt in ("-f", "--file"):
            file = arg
        elif opt in ("-o", "--output"):
            output = arg

    if file == "" or output == "":
        help()
        sys.exit(2)

    main(file, output)
