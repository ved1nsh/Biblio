import sys
with open('old.txt', 'r') as f: old = f.read()
with open('new.txt', 'r') as f: new = f.read()
with open('lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart', 'r') as f: content = f.read()
with open('lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart', 'w') as f: f.write(content.replace(old, new))
