#!/usr/bin/env python3
# -*- coding:utf-8 -*-

# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (C) 2022-2023 xqyjlj<xqyjlj@126.com>
#
# @author      xqyjlj
# @file        xml_to_yaml.py
#
# Change Logs:
# Date           Author       Notes
# ------------   ----------   -----------------------------------------------
# 2023-01-02     xqyjlj       initial version
#

import yaml
import os, sys, getopt
import xml.etree.ElementTree as Et


def help():
    """
example:
    python ./xml_to_yaml.py -t pinout -f pinout.xml -o pinout.yml
    """
    print("usage: " + os.path.basename(__file__) + " [<options>] ")
    print("")
    print("    -h, --help       print this help")
    print("    -t, --type       type of xml file")
    print("    -f, --file       xml file")
    print("    -o, --output     output file")


def pinout(tree, output):
    """
convert pinout xml to yml
    """
    """
example:
<Pinout>
    <Pins>
        <Pin Name="PE2" Position="1" Type="I/O">
            <Functions>
                <Function Name="FSMC-A23" />
                <Function Name="SYS-TRACECLK" />
                <Function Name="GPIO-Input" Type="GPIO" Mode="std:input" />
                <Function Name="GPIO-Output" Type="GPIO" Mode="Output-Std" />
                <Function Name="GPIO-Analog" Type="GPIO" Mode="Analog-Std" />
                <Function Name="EVENTOUT" Type="GPIO" Mode="Eventout-Std" />
                <Function Name="GPIO-EXTI" Type="GPIO" Mode="Exti-Std" />
            </Functions>
        </Pin>
    </Pins>
</Pinout>
    """
    root = tree.getroot()
    pins = root.findall("Pins/Pin")
    yml = []
    for pin in pins:
        yml.append(pin.attrib["Name"] + ":")
        if "Position" in pin.attrib:
            yml.append("  Position: " + pin.attrib["Position"])
        if "Type" in pin.attrib:
            yml.append("  Type: " + pin.attrib["Type"])
        functions = pin.findall("Functions/Function")
        if len(functions) > 0:
            yml.append("  Functions:")
        for function in functions:
            type = ""
            mode = ""
            if "Type" in function.attrib:
                type = "Type: {type}".format(type=function.attrib["Type"])
            if "Mode" in function.attrib:
                mode = "Mode: {mode}".format(mode=function.attrib["Mode"])
            struct = ""
            if type == "" and mode != "":
                struct = "{{ {type} }}".format(type=type)
            elif type != "" and mode == "":
                struct = "{{ {mode} }}".format(mode=mode)
            elif type != "" and mode != "":
                struct = "{{ {type}, {mode} }}".format(type=type, mode=mode)
            yml.append("    " + function.attrib["Name"] + ": {struct}".format(struct=struct))
    with open(output, "w", encoding="utf-8") as fp:
        fp.write("\n".join(yml) + "\n")


def clock_control(tree, output):
    """
convert pinout xml to yml
    """
    """
<Control ID="7" Name="MCO-Out" Type="Label" Multiple="1000000">
    <Signals>
        <Signal Source="PLL-HSE-Mul" Value="2" Operator="/">
            <Dependencies>CSP_USING_CLOCK_MCO_PLL_DIV2</Dependencies>
        </Signal>
        <Signal SourceValue="8000000">
            <Dependencies>CSP_USING_CLOCK_MCO_HSI</Dependencies>
        </Signal>
        <Signal Source="HSE-Input">
            <Dependencies>CSP_USING_CLOCK_MCO_HSE</Dependencies>
        </Signal>
        <Signal Source="SYS-Clk">
            <Dependencies>CSP_USING_CLOCK_MCO_SYSTEM_CLK</Dependencies>
        </Signal>
    </Signals>
</Control>
    """
    root = tree.getroot()
    controls = root.findall("Controls/Control")
    yml = {}
    yml["Controls"] = {}
    for control in controls:
        id = control.attrib.pop('ID')
        if "Multiple" in control.attrib:
            control.attrib["Multiple"] = int(control.attrib["Multiple"])
        if "IsChecked" in control.attrib:
            control.attrib["IsChecked"] = bool(control.attrib["IsChecked"])
        if "DefaultIndex" in control.attrib:
            control.attrib["DefaultIndex"] = int(control.attrib["DefaultIndex"])
        if "DefaultValue" in control.attrib:
            control.attrib["DefaultValue"] = float(control.attrib["DefaultValue"])
        yml["Controls"][int(id)] = {}
        yml["Controls"][int(id)]["Base"] = control.attrib
    with open(output, "w", encoding="utf-8") as fp:
        fp.write(yaml.dump(yml, sort_keys=False) + "\n")


def main(type, file, output):
    tree = Et.parse(file)
    eval(type)(tree, output)


if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "ht:f:o:", ["help", "type=", "file=", "output="])
    except getopt.GetoptError:
        help()
        sys.exit(2)

    type = ""
    file = ""
    output = ""
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit()
        elif opt in ("-t", "--type"):
            type = arg
        elif opt in ("-f", "--file"):
            file = arg
        elif opt in ("-o", "--output"):
            output = arg

    if type == "" or file == "" or output == "":
        help()
        sys.exit(2)

    main(type, file, output)
