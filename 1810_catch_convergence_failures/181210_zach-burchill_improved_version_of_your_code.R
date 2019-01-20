## Problem: How to handle convergence failures in power simulations?

# Zach's improved version:

# From Slack HLP (posted 18-10-21):
# Here's a quick "improved" version of your code. Note that this relies heavily
# on the "purrr" package, and its "secret sauce" (the function `collect_all`)
# comes from a personal package of mine, "zplyr" (completely unrelated to any
# "-plyr" package). If you want to install it, you can use 
# `devtools::install_github("burchill/zplyr")`, but you could also just copy
# the code from https://github.com/burchill/zplyr/blob/master/R/collect_all.R
# (with attribution, of course!).
# Every line I changed in the top half I added the comment "CHANGED" after it.

library("lme4")
library("purrr") # CHANGED
# if zplyr not installed, run following line
# devtools::install_github("burchill/zplyr")
library("zplyr")
library("dplyr")
library("broom")


# Create data set that follows Poisson distribution -----------------------

# Function creates Poisson-distributed data; lambda varies between subjects
poiss_data <- function(
  N = 8,  # number of subjects
  obs = 4,  # nb of observations (items) per subject
  cond = 2,  # number of (between-subject) conditions
  seed_val = 1 # A seed to set to so it's replicable  # CHANGED
) {
  # design matrix
  df <- data.frame(
    Condition = rep(LETTERS[1:cond], each = N * obs / cond),
    Subj = rep(seq(N), each = obs),
    Item = seq(obs)
  )
  # set the seed # CHANGED
  set.seed(seed_val) # CHANGED
  
  # random Poisson counts
  df$lambdas <- rep(runif(N, 1, 10), each = obs)
  df$count <- rpois(N * obs, lambda = df$lambdas)
  df
}

# example
poiss_data() %>% head


# Setting up the simulations # CHANGED
n_sims <- 3 # CHANGED
sim_seeds <- 1:n_sims # CHANGED



# Fit GLMMs using dplyr::do -----------------------------------------------

# run n_sims simulations and fit Poisson model to each
# EVERYTHING BELOW HERE CHANGED! ----------------------------------------------
fit_poi_glmm <- function(seed_list = c(1, 2, 3)) {
  purrr::map(seed_list, ~poiss_data(seed_val = .)) %>%
    purrr::map(
      # This is my special sauce ;)
      function(df) {
        zplyr::collect_all({
          glmer(count ~ 1 + Condition + (1 | Subj) + (1 + Condition | Item),
                data = df, family = "poisson")
        })
      }
    )
}

# Had to change the seed to 38 to get a non-convergence
myfms <- fit_poi_glmm(38:40)
# myfms <- fit_poi_glmm(38:44)
myfms %>% purrr::map(~.$warnings) # see which has warnings
myfms %>% purrr::map(~.$message)    # show the values
myfms %>% purrr::map(~.$value)    # show the values

# A bit of fanciness that turns everything into a big nested data frame
# It doesn't need to be this complicated
my_summaries <- myfms %>% purrr::imap_dfr(
  function(single, iter) {
    single$value %>%
      broom::tidy() %>%
      tibble::as_tibble() %>%
      mutate(k = as.numeric(iter)) %>%
      tidyr::nest(-k) %>%
      mutate(messages = paste0(single$messages, collapse="--------"),
             warnings = paste0(single$warnings, collapse="--------"),
             errors = paste0(single$errors, collapse="--------"))
  })
my_summaries %>%
  filter(!grepl("converge", warnings)) %>% # get rid of any models with the word "converged" in the warnings  (you can change this to whatever)
  tidyr::unnest() %>%
  select(-messages:-errors)

myfms[[1]]$value %>% summary
myfms[[1]]$message

