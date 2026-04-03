import re
file_path = "lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart"
with open(file_path, "r") as f: text = f.read()
text = re.sub(r"\.withOpacity\((.*?)\)", r".withValues(alpha: \1)", text)
text = text.replace("aspectRatio: 1 / 1.45", "aspectRatio: 1 / 1.38")
text = text.replace("BorderRadius.circular(8)", "BorderRadius.circular(12)")
text = text.replace("blurRadius: 6,", "blurRadius: 12,")
text = text.replace("offset: const Offset(2, 3),", "offset: const Offset(0, 6),")
text = text.replace("color: Colors.black.withValues(alpha: 0.15)", "color: Colors.black.withValues(alpha: 0.2)")
text = re.sub(r"fit:\s*BoxFit\s*\.\s*fill", "fit: BoxFit.cover", text)
with open(file_path, "w") as f: f.write(text)
