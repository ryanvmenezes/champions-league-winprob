# source: https://www.win.tue.nl/~rmcastro/AppStat2013/files/demo_smoothing.R

###
### Adapted from notes/scripts by Brett Presnell
### http://www.stat.ufl.edu/~presnell/Courses/Smoothing/R-transcripts/2003-10-27.Rt
###

help(package=locfit)
library(locfit)
help(locfit)
help(locfit.raw)

#
# close all open graphs
#
graphics.off()

#
# Load motorcycle data
#

library(MASS)
# get motorcyle data, for info: type "?mcycle"
x <- mcycle$times
y <- mcycle$accel
n <- length(x)

#
# polynomial regression
#
par(mfrow=c(2,1))
plot(x,y,main='Polynomial regression',lwd=2,xlab='time',ylab='acceleration')
lines(x, fitted(lm(y ~ poly(x,3))),col='blue',lwd=2)
lines(x, fitted(lm(y ~ poly(x,8))),col='red',lwd=2)
legend("bottomright", c("degree=3","degree=8"), col = c("blue","red"),lty=c(1,1))

#
# Kernel Smoothing
#
fit <- locfit(accel ~ times,data=mcycle, alpha = 0.5)
fit
names(fit)
class(fit)
# help(plot.locfit)

plot(fit, get.data = TRUE)

#alpha is the bandwidth, but specified in a different way than in class, namely it is the fraction of data points that are supported by the kernel (therefore it is a "bandwidth" that depends on the design) - more on this below

# 
# The following call produces the same fit, but doesn't use the S
# language modelling formula.
locfit.raw(y, x, alpha = 0.5)

#locfit uses local quadratic polynomials by defect, to use local linear fits add the argument deg=1, for the Nadaraya-Watson estimator take deg=0 (sometimes there are numerical issues with this one)

fit <- locfit(y ~ x, alpha = 0.2,deg=0)
plot(fit,get.data=TRUE)

# 
# Try a variety of bandwidths:
# 
alp <- 0.1 * (9:1)
par(mfrow = c(3,3))
for (a in alp) 
{
  fit <- locfit(y ~ x, alpha = a)
  plot(x,y,main = paste("alpha =", a))
  lines(fit,col=2,lwd=2)
}

par(mfrow = c(1,1))

#
# By default locfit() uses nearest neighbor bandwidths with span
# 0.7. For a constant (global) bandwidth, specify alpha as a two
# component vector with the first component zero, and the second
# the desired bandwidth.
# 

fit <- locfit(y ~ x, alpha = c(0, 0.12))
plot(fit, get.data = TRUE)

# 
# More generally if both the span (first component of alpha) and
# the fixed bandwidth (second component) are nonzero, than at each
# x the maximum of the fixed bandwidth and the nearest neighbor
# bandwidth (for that x) is used.
# 
# The deg argument specifies the degree of the local polynomial
# (the default is deg = 2).  The kern argument specifies the
# kernel (the default if kern = "tcub" for the tricube kernel.
# 

# The following confidence band assumes that the error variance is
# constant and that the estimator is unbiased (or nearly so).
# 
fit <- locfit(y ~ x, alpha = 0.5)
plot(fit, band = "global")

#
# The degrees of freedom are available using fit$dp
#
# The effective degrees of freedom = tr(L)
fit$dp["df1"]
# The fitted degrees of freedom = tr(L'*L)
fit$dp["df2"]

#
#The trace matrix can also be obtained, using
#
L <- t(locfit(y ~ x,alpha = 0.5, geth=1,ev=dat()))

#Therefore, the effective degrees of freedom are given by
sum(diag(L))

#and the fitted degrees of freedom are given by
sum(diag(t(L)%*%L))

#Also interesting is the number of degrees of freedom when estimating the variance:
2*fit$dp["df1"]-fit$dp["df2"]

# 
# Here's one way of computing the GCV by hand.
# 
names(fit)
fit$dp
(1/n) * (-2 * fit$dp["lk"]) / (1 - fit$dp["df1"]/n)^2

# 
# gcv() does this automatically.
# 
gcv(y ~ x, alpha = 0.5)

# 
# This is not be exact, because the fit may not be computed exactly at
# each x_i, but rather is interpolated from a fit on a suitably
# chosen grid (not equally spaced here).  To the exact GCV run (might be slow for large data sets)
# 
gcv(y ~ x, alpha = 0.5, ev = dat())

# 
# gcvplot() is a wrapper for gcv() that computes the GCV and plots
# it for a sequence of spans or bandwidths.  cpplot() does the
# same for Cp.
# 
par(mfrow = c(2,2))
gcvplot(y ~ x, alpha = seq(0.2, 0.8, by = 0.01))
cpplot(y ~ x, alpha = seq(0.2, 0.8, by = 0.01))
# 
# Note that each smoothing parameter here is a nearest neighbor
# span.  To specify constant bandwidths, alpha should be a two
# column matrix with first column 0, e.g.,
# 
a <- cbind(0, seq(0.04, 0.24, by = 0.01))
gcvplot(NOx ~ E, data = ethanol, alpha = a)
cpplot(NOx ~ E, data = ethanol, alpha = a)

par(mfrow = c(1,1))
# 
# Here are two ways to compute the exact cross validation sum of
# squares.
# 
# First the direct method, which actually computes the leave one
# out estimators at each design point:
# 
fit <- locfit(y ~ x, data = mcycle, alpha = 0.5, ev=dat(cv=TRUE))
(-2 * fit$dp["lk"]) / n
# 
# Or evaluating the estimator exactly at each data point and using
# the alternative formula using residuals and influence values
# (diagonal entries from the smoothing matrix:
# 
fit <- locfit(y ~ x, alpha = 0.5, ev=dat())
r <- residuals(fit)
infl <- fitted(fit, what = "infl")
mean((r/(1-infl))^2)
# 
# Either of these will be slow for really large data sets.  Here
# is an approximation that uses interpolation with the default
# evaluation at a set of grid points:
# 
fit <- locfit(y ~ x, alpha = 0.5)
r <- residuals(fit)
infl <- fitted(fit, what = "infl")
mean((r/(1-infl))^2)

# 
# Finally here is another approximation:
# 
mean(residuals(fit, cv = TRUE)^2)

# 
# As an aside, here are the various degrees of freedom as a
# function of bandwidth:
# 
a <- seq(0.04, 0.24, by = 0.02)
df <- matrix(nrow=length(a), ncol=3)
for (i in seq(along=a)) df[i,1:2] <- locfit(y ~ x, alpha = c(0, a[i]))$dp[c("df1","df2")]
df[,3] <- 2*df[,1] - df[,2]
plot(c(min(a), max(a)), c(min(df), max(df)), xlab = "bandwidth", ylab = "df", type = "n")
lines(a, df[,1])
lines(a, df[,2], lty=2)
lines(a, df[,3], lty=3)
legend("topright", c("Effective df","Fitted df","Variance df"), lty=1:3)
# 
# df2 and df3 as functions of df1:
# 
plot(c(min(df), max(df)), c(min(df), max(df)), xlab = "df1", ylab = "", type = "n")
abline(0,1)
lines(df[,1], df[,2], lty=2)
lines(df[,1], df[,3], lty=3)
# 
# Let's see more of the limiting behavior:
# 
a <- seq(0.02, 0.9, by = 0.05)
df <- matrix(nrow=length(a), ncol=3)
for (i in seq(along=a)) df[i,1:2] <- locfit(y ~ x, alpha = c(0, a[i]))$dp[c("df1","df2")]
df[,3] <- 2*df[,1] - df[,2]
plot(c(min(a), max(a)), c(min(df), max(df)), xlab = "bandwidth", ylab = "df", type = "n")
lines(a, df[,1])
lines(a, df[,2], lty=2)
lines(a, df[,3], lty=3)

#As the bandwidth gets larger (more smoothing) all of these should approach the degree of the local polynomials
abline(h = 3)
remember that the default is local quadratic
legend("topright", c("Effective df","Fitted df","Variance df"), lty=1:3)