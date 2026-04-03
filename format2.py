import re
file_path = "lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart"
with open(file_path, "r") as f: text = f.read()
text = re.sub(r"\(54 \* widget\.scale\)\.clamp\(46\.0, 60\.0\)", "(34 * widget.scale).clamp(30.0, 40.0)", text)
text = re.sub(r"maxLines:\s*2,\s*\n\s*overflow:\s*TextOverflow\.ellipsis,\s*\}\),\s*SizedBox\(height:\s*headerGap\),", "maxLines: 1,\noverflow: TextOverflow.ellipsis,\n),\nSizedBox(height: headerGap),", text)
text = text.replace("maxLines: 2,", "maxLines: 1,")
with open(file_path, "w") as f: f.write(text)
