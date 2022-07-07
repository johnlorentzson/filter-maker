# Filter Maker

Filter Maker lets users make filters out of predicates and keys,
similar to those GUI email filter tools. The developer using the
library simply provides a set of predicates (and their names) as well
as some keys (and their names) and the items to filter.

Note that I don't know how to make CLIM programs look (or work) good
so if you think you can do better you're probably right, feel free
to send a pull request.

## Example usage

```lisp
(filter
 '((string-not-equal "String isn't" 2)
   (string-equal "String is" 2)
   (string-all-uppercase-p "String is uppercase" 1))
 '((first "First")
   (second "Second")
   (third "Third"))
 '(("FIRST" "secoNd" "3")
   ("FIRST" "yup" "hello")))
```

This will open a Filter Maker window letting the user make a filter
using the predicates STRING-NOT-EQUAL, STRING-EQUAL and STRING-ALL-UPPERCASE-P.
The keys available will be FIRST, SECOND and THIRD. Once a filter is
constructed and the user clicks "OK" the filter will be applied to
the list of items. The numbers after the names are the predicate's argument count.
For now, this must be 1 or 2. I plan to support any number of arguments
eventually.

## Known problems

- Predicate argument counts other than 1 or 2 aren't supported.
- Looks ugly (because I don't understand CLIM well enough to make things nice).
- And... probably something else that I'm forgetting.
