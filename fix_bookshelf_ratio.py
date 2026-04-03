import re

file_path = "lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart"
with open(file_path, "r") as f:
    text = f.read()

# I want to isolate the itemBuilder: (context, index) { ... }
start_idx = text.find("itemBuilder: (context, index) {")

# find the end of itemBuilder
# the itemBuilder ends where ListView.separated ends.
# We can find ListView.separated and replace its entire block easily.
start_lv = text.find("ListView.separated(")
end_lv = text.find("),", start_lv) # not sufficient...

