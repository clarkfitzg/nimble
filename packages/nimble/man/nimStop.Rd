% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in Rtmp9wH6ZH/file2ef7725fe91c
\name{nimStop}
\alias{nimStop}
\title{Halt execution of a nimbleFunction function method.  Part of the NIMBLE language}
\usage{
nimStop(msg)
}
\arguments{
\item{msg}{Character object to be output as an error message}
}
\description{
Halt execution of a nimbleFunction function method.  Part of the NIMBLE language
}
\details{
The NIMBLE stop is similar to the native R stop, but it takes only one argument, the error message to be output.  During uncompiled NIMBLE execution, nimStop simply calls R's stop funtion. During compiled execution it calls the error function from the R headers.  stop is an alias for nimStop in the NIMBLE language
}
\author{
Perry de Valpine
}

