context("perryTuning - one replication of CV")


## load packages
library("perry", quietly=TRUE)
library("perryExamples", quietly=TRUE)

## set seed for reproducibility
set.seed(1234)

## generate data for tests
n <- 20
x <- rnorm(n)
y <- x + rnorm(n)
x <- as.matrix(x)
xy <- data.frame(x, y)

## set up cross-validation folds
K <- 5
R <- 1
folds <- cvFolds(n, K, R)

## set up function call to lmrob() and lts()
lmrobCall <- call("lmrob", formula = y~x)
ltsCall <- call("ltsReg", alpha=0.75)

## tuning parameters for lmrob() and lts()
tuning.psi <- c(3.443689, 4.685061)
lmrobTuning <- list(tuning.psi = tuning.psi)
alpha <- c(0.5, 0.75)
ltsTuning <- list(alpha=alpha)


## run tests

test_that("univariate response yields correct \"perryTuning\" object", {
        ## MM-regression
        lmrobCV <- perryTuning(lmrobCall, data=xy, y=xy$y, tuning=lmrobTuning, 
            splits=folds, cost=rtmspe)
        
        expect_is(lmrobCV, "perryTuning")
        # check prediction error
        lmrobPE <- lmrobCV$pe
        expect_is(lmrobPE, "data.frame")
        expect_equal(dim(lmrobPE), c(length(tuning.psi), 2))
        # check that standard error is NA
        lmrobSE <- lmrobCV$se
        expect_is(lmrobSE, "data.frame")
        expect_equal(dim(lmrobSE), c(length(tuning.psi), 2))
        expect_true(all(is.na(lmrobSE[, -1])))
        # check that there are no replications
        expect_equal(lmrobCV$reps, NULL)
        # check predictions
        lmrobYHat <- lmrobCV$yHat
        expect_is(lmrobYHat, "list")
        expect_equal(length(lmrobYHat), length(tuning.psi))
        for(yHat in lmrobYHat) {
            expect_is(yHat, "list")
            expect_equal(length(yHat), R)
        }
        
        ## reweighted and raw LTS
        ltsCV <- perryTuning(ltsCall, x=x, y=y, tuning=ltsTuning, 
            predictArgs=list(fit="both"), splits=folds)
        
        expect_is(ltsCV, "perryTuning")
        # check prediction error
        ltsPE <- ltsCV$pe
        expect_is(ltsPE, "data.frame")
        expect_equal(dim(ltsPE), c(length(alpha), 3))
        # check that standard error is NA
        ltsSE <- ltsCV$se
        expect_is(ltsSE, "data.frame")
        expect_equal(dim(ltsSE), c(length(alpha), 3))
        expect_true(all(is.na(ltsSE[, -1])))
        # check that there are no replications
        expect_equal(ltsCV$reps, NULL)
        # check predictions
        ltsYHat <- ltsCV$yHat
        expect_is(ltsYHat, "list")
        expect_equal(length(ltsYHat), length(tuning.psi))
        for(yHat in ltsYHat) {
            expect_is(yHat, "list")
            expect_equal(length(yHat), R)
        }
    })

test_that("including standard error gives correct data frame", {
        ## MM-regression
        lmrobCV <- perryTuning(lmrobCall, data=xy, y=xy$y, tuning=lmrobTuning, 
            splits=folds, cost=rtmspe, costArgs=list(includeSE=TRUE))
        
        expect_is(lmrobCV, "perryTuning")
        # check standard error
        lmrobSE <- lmrobCV$se
        expect_is(lmrobSE, "data.frame")
        expect_equal(dim(lmrobSE), c(length(tuning.psi), 2))
        expect_false(any(is.na(lmrobSE)))
        
        ## reweighted and raw LTS
        ltsCV <- perryTuning(ltsCall, x=x, y=y, tuning=ltsTuning, 
            splits=folds, predictArgs=list(fit="both"), cost=rtmspe, 
            costArgs=list(includeSE=TRUE))
        
        expect_is(ltsCV, "perryTuning")
        # check standard error
        ltsSE <- ltsCV$se
        expect_is(ltsSE, "data.frame")
        expect_equal(dim(ltsSE), c(length(alpha), 3))
        expect_false(any(is.na(ltsSE)))
    })
