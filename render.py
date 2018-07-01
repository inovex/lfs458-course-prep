#!/usr/bin/env python3

"""This script renderes the main.tf for terraform since
   terraform doesn't support the count functionality for modules
   see: https://github.com/hashicorp/terraform/issues/953"""

import os
from jinja2 import Environment, FileSystemLoader
import yaml

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))


def render():
    """The render function renderes the actual main.tf"""
    students = {}
    with open("students.yml", 'r') as stream:
        try:
            students = yaml.load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    j2_env = Environment(loader=FileSystemLoader(CURRENT_DIR),
                         trim_blocks=True)

    template = j2_env.get_template('main.tf.j2')

    with open("main.tf", "w") as text_file:
        text_file.write(template.render(students))


if __name__ == '__main__':
    render()
