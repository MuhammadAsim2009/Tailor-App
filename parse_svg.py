import xml.etree.ElementTree as ET
import re

tree = ET.parse(r'C:\Users\WinsOft Computer\Desktop\Irfan_tailor_logo-removebg-preview (1).svg')
root = tree.getroot()

dart_code = "import 'package:flutter/material.dart';\n\n"
dart_code += "class LogoSvgPath {\n"
dart_code += "  final String d;\n"
dart_code += "  final Color color;\n"
dart_code += "  final double dx;\n"
dart_code += "  final double dy;\n\n"
dart_code += "  const LogoSvgPath(this.d, this.color, this.dx, this.dy);\n"
dart_code += "}\n\n"
dart_code += "final List<LogoSvgPath> logoPaths = [\n"

namespace = {'svg': 'http://www.w3.org/2000/svg'}
for p in root.findall('.//svg:path', namespace):
    d = p.get('d', '')
    fill = p.get('fill', '#000000')
    if fill.startswith('#'):
        fill = '0xFF' + fill[1:].upper()
    else:
        fill = '0xFF000000'
    transform = p.get('transform', '')
    dx, dy = 0.0, 0.0
    if 'translate' in transform:
        m = re.search(r'translate\(([^,]+),([^)]+)\)', transform)
        if m:
            dx = float(m.group(1))
            dy = float(m.group(2))
    dart_code += f"  LogoSvgPath('{d}', Color({fill}), {dx}, {dy}),\n"

dart_code += "];\n"

with open(r'd:\tailor_app\lib\tailor_icon_paths.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)
