% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in Rtmp9wH6ZH/file2ef72cd18718
\name{nimbleFunctionVirtual}
\alias{nimbleFunctionVirtual}
\title{create a virtual nimbleFunction, a base class for other nimbleFunctions}
\usage{
nimbleFunctionVirtual(contains = NULL, run = function() { },
  methods = list(), name = NA)
}
\arguments{
\item{contains}{Not yet functional}

\item{run}{A NIMBLE function that will only be used to inspect its argument types and returnType.}

\item{methods}{An optional named list of NIMBLE functions that will also only be used for inspecting argument types and returnTypes.}

\item{name}{An optional name used internally by the NIMBLE compiled.  This is usually omitted and NIMBLE provides one.}
}
\value{
An object that can be passed as the \code{contains} argument to \code{nimbleFunction} or as the argument to \code{nimbleFunctionList}
}
\description{
define argument types and returnType for the \code{run} function and any \code{methods}, to be used in the \code{contains} argument of \code{nimbleFunction}
}
\details{
See the NIMBLE User Manual section on nimbleFunctionLists for explanation of how to use a virtual nimbleFunction.
}
\author{
NIMBLE development team
}
\seealso{
\link{nimbleFunction}
}

