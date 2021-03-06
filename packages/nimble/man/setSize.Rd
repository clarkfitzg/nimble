% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in Rtmp9wH6ZH/file2ef741aa61e1
\name{setSize}
\alias{setSize}
\title{set the size of a numeric variable in NIMBLE}
\usage{
setSize(numObj, ..., row)
}
\arguments{
\item{numObj}{This is the object to be resized}

\item{...}{sizes, provided as scalars, in order, with exactly as many as needed for the object}

\item{row}{Optional argument that is not currently used}
}
\description{
set the size of a numeric variable in NIMBLE.  This works in R and NIMBLE, but in R it usually has no effect.
}
\details{
This function is part of the NIMBLE language.  Its purpose is to explicitly resize a multivariate object (vector, matrix or array), currently up to 4 dimensions.  Explicit resizing is not needed when an entire object is assigned to.  For example, in \code{Y <- A \%*\% B}, where A and B are matrices, \code{Y} will be resized automatically.  Explicit resizing is necessary when assignment will be by indexed elements or blocks, if the object is not already an appropriate size for the assignment.  E.g. prior to \code{Y[5:10] <- A \%*\% B}, one can use setSize to ensure that \code{Y} has a size (length) of at least 10.

This does work in uncompiled (R) and well as compiled execution, but in some cases it is only necessary for compiled execution. During uncompiled execution, it may not catch bugs due to resizing because some R objects will be dynamically resized during assignments anyway.
}
\author{
NIMBLE development team
}

