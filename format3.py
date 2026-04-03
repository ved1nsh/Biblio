import re
file_path = "lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart"
with open(file_path, "r") as f: text = f.read()
text = text.replace("book.title,\n                                                      maxLines: 1,", "book.title,\n                                                      maxLines: 2,")
with open(file_path, "w") as f: f.write(text)
