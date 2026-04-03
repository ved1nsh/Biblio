import re
file_path = "lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart"
with open(file_path, "r") as f: text = f.read()
text = re.sub(r"width: \(100 \* widget\.scale\)\.clamp\(\s*90\.0,\s*110\.0,\s*\),", "width: coverWidth,", text)
with open(file_path, "w") as f: f.write(text)
