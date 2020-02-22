#!/usr/bin/env python
# coding: utf-8

from __future__ import print_function

import os
import argparse

from fnmatch import filter
from xml.dom.minidom import Document, parse


def dir_path(string):
    if os.path.isdir(string):
        return string
    else:
        raise ValueError("Addons repository root must be a directory")


def find_files(dir, pattern):
    for root, _, filenames in os.walk(dir):
        for filename in filter(filenames, pattern):
            yield os.path.join(root, filename)


def repository_xml(xml_list):
    result_xml = Document()

    xml_root = result_xml.createElement('addons')
    result_xml.appendChild(xml_root)

    for xml_file in xml_list:
        xml = parse(xml_file)
        xml_root.appendChild(xml.firstChild)

    xml_text = result_xml.toprettyxml(indent="    ", encoding='utf-8')
    xml_text = os.linesep.join([s for s in xml_text.splitlines() if s.strip()])

    return xml_text


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Combines all addon.xml files from addons_root into single repository XML.')

    parser.add_argument('-o', '--output', required=True, help="Output file path", type=argparse.FileType('wb'))
    parser.add_argument('addons_root', help="Addons repository root", type=dir_path)

    args = parser.parse_args()

    addon_xmls = sorted([f for f in find_files(args.addons_root, 'addon.xml')])

    repo_xml_text = repository_xml(addon_xmls)

    args.output.write(repo_xml_text)
