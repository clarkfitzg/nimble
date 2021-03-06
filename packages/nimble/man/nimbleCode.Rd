% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in Rtmp9wH6ZH/file2ef7191c31aa
\name{nimbleCode}
\alias{nimbleCode}
\title{Turn BUGS model code into an object for use in \code{nimbleModel} or \code{readBUGSmodel}}
\usage{
nimbleCode(code)
}
\arguments{
\item{code}{expression providing the code for the model}
}
\description{
Simply keeps model code as an R call object, the form needed by \link{nimbleModel} and optionally usable by \link{readBUGSmodel}
}
\details{
It is equivalent to use the R function \code{quote}.  \code{nimbleCode} is simply provided as a more readable alternative for NIMBLE users not familiar with \code{quote}.
}
\examples{
code <- nimbleCode({
    x ~ dnorm(mu, sd = 1)
    mu ~ dnorm(0, sd = prior_sd)
})
}
\author{
Daniel Turek
}

