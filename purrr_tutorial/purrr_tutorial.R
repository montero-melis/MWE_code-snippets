# https://jennybc.github.io/purrr-tutorial/index.html

# I'm starting with:
# https://jennybc.github.io/purrr-tutorial/ls00_inspect-explore.html

library(purrr)
# devtools::install_github("jennybc/repurrrsive")
library(repurrrsive)

str(wesanderson)

# Introduction to purrr::map(): extract elements
# https://jennybc.github.io/purrr-tutorial/ls01_map-name-position-shortcuts.html

str(got_chars)

# extracts an element based on its name
map(got_chars[1:4], "name")
map(got_chars[1:4], "gender")

map(head(got_chars), "name")
map_chr(head(got_chars), "name")
map_chr(got_chars, "name")

# What list contains Sansa (Stark)
grep("Sansa", map_chr(got_chars, "name"))


# extracts an element based on its position
map(got_chars[1:4], 3)


# Or use with the pipe
head(got_chars) %>% 
  map("name")
head(got_chars) %>% 
  map(3)

# Coerce output to "int" type:
map_int(got_chars[1:4], "id")
# But the requested output has to make sense
map_int(got_chars[1:4], "name")
map_lgl(got_chars[1:4], "name")



# Extract multiple values -------------------------------------------------

# What if you want to retrieve multiple elements? Such as the character’s name
# and culture? First, recall how we do this with the list for a single user:
got_chars[[3]][c("name", "culture", "gender", "born")]

?map
# map(.x, .f, ...)

# The function .f will be [. And we finally get to use ...! 
# This is where we pass the character vector of the names of our desired 
# elements. We inspect the result for two characters.
map(got_chars, `[`, c("name", "culture", "gender", "born"))
x <- map(got_chars, `[`, c("name", "culture", "gender", "born"))
str(x[16:17])
