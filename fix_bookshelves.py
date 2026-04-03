import re

file_path = "lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart"

with open(file_path, "r") as f:
    content = f.read()

# 1. Replace the first AspectRatio wrapper inside the View Shelf tile
content = content.replace("child: AspectRatio(", "child: Align(alignment: Alignment.bottomLeft, child: AspectRatio(")
# We need to add the closing parenthesis for Align too. But since there are two AspectRatio, we need to balance them. 
# It's better to replace the whole ListView.separated section!

