## Problem: How to handle convergence failures in power simulations?

library("lme4")
library("plyr")
library("dplyr")
library("broom")


# Create data set that follows Poisson distribution -----------------------

# Function creates Poisson-distributed data; lambda varies between subjects
poiss_data <- function(
  N = 8,  # number of subjects
  obs = 4,  # nb of observations (items) per subject
  cond = 2  # number of (between-subject) conditions
  ) {
  # design matrix
  df <- data.frame(
    Condition = rep(LETTERS[1:cond], each = N * obs / cond),
    Subj = rep(seq(N), each = obs),
    Item = seq(obs)
  )
  # random Poisson counts
  df$lambdas <- rep(runif(N, 1, 10), each = obs)
  df$count <- rpois(N * obs, lambda = df$lambdas)
  df
}

# example
poiss_data()


# Fit GLMMs using dplyr::do -----------------------------------------------

# run n_sims simulations and fit Poisson model to each
fit_poi_glmm <- function(n_sims = 3) {
  simulated_datasets <- rdply(n_sims, poiss_data()) %>% rename(Sim = .n)
  # fit models using dplyr::do (https://dplyr.tidyverse.org/reference/do.html)
  fitted <- simulated_datasets %>% group_by(Sim) %>%
    do(fm = glmer(
      count ~ 1 + Condition + (1 | Subj) + (1 + Condition | Item),
      data = ., family = "poisson"))
  fitted
}

# This issues a failure-to-converge warning
set.seed(345)
myfms <- fit_poi_glmm()

# Warning message:
#   In checkConv(attr(opt, "derivs"), opt$par, ctrl = control$checkConv,  :
#   Model failed to converge with max|grad| = 0.00341154 (tol = 0.001, component 1)


# But convergence failures are ignored by broom::tidy()! ------------------

# Now I'd like to use the broom::tidy() function to extract coefficients from
# fitted models, but it seems to take all the models independently of 
# convergence failures:
my_summaries <- myfms %>% tidy(fm)

# Info about convergence failures seems to be lost
my_summaries
