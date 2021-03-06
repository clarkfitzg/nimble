% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in Rtmp9wH6ZH/file2ef73eb778fd
\docType{class}
\name{MCMCconf-class}
\alias{MCMCconf}
\alias{MCMCconf-class}
\alias{addMonitors}
\alias{addMonitors2}
\alias{addSampler}
\alias{getMonitors}
\alias{getSamplers}
\alias{printSamplers}
\alias{removeSamplers}
\alias{resetMonitors}
\alias{setSamplers}
\alias{setThin}
\alias{setThin2}
\title{Class \code{MCMCconf}}
\description{
Objects of this class configure an MCMC algorithm, specific to a particular model.  Objects are normally created by calling \link{configureMCMC}.
Given an MCMCconf object, the actual MCMC function can be built by calling \link{buildMCMC}\code{(conf)}.
See documentation below for method initialize() for details of creating an MCMCconf object.
}
\section{Methods}{

\describe{
\item{\code{addMonitors(vars, ind = 1, print = TRUE)}}{Adds variables to the list of monitors.

Arguments:

vars: A character vector of indexed nodes, or variables, which are to be monitored.  These are added onto the current monitors list.

print: A logical argument, specifying whether to print all current monitors.

Details: See the initialize() function
            }

\item{\code{addMonitors2(vars, print = TRUE)}}{Adds variables to the list of monitors2.

Arguments:

vars: A character vector of indexed nodes, or variables, which are to be monitored.  These are added onto the current monitors2 list.

print: A logical argument, specifying whether to print all current monitors.

Details: See the initialize() function
            }

\item{\code{addSampler(target, type = "RW", control = list(), print = FALSE, name)}}{Adds a sampler to the list of samplers contained in the MCMCconf object.

Arguments:

target: The target node or nodes to be sampled.  This may be specified as a character vector of model node and/or variable names.  This argument is required.

type: The type of sampler to add, specified as either a character string or a nimbleFunction object.  If the character argument type='newSamplerType', then either newSamplerType or sampler_newSamplertype must correspond to a nimbleFunction (i.e. a function returned by nimbleFunction, not a specialized nimbleFunction).  Alternatively, the type argument may be provided as a nimbleFunction itself rather than its name.  In that case, the 'name' argument may also be supplied to provide a meaningful name for this sampler.  The default value is 'RW' which specifies scalar adaptive Metropolis-Hastings sampling with a normal proposal distribution. This default will result in an error if 'target' specifies more than one target node.

control: A list of control arguments specific to the sampler function.
These will override the defaults provided in the NIMBLE system option 'MCMCcontrolDefaultList', and any specified in the control list argument to configureMCMC().
An error results if the sampler function requires any control elements which are 
not present in this argument, the control list argument to configureMCMC(), or in the NIMBLE system option 'MCMCcontrolDefaultList'.

print: Logical argument, specifying whether to print the details of the newly added sampler, as well as its position in the list of MCMC samplers.

name: Optional character string name for the sampler, which is used by the printSamplers method.  If 'name' is not provided, the 'type' argument is used to generate the sampler name.

Details: A single instance of the newly configured sampler is added to the end of the list of samplers for this MCMCconf object.

Invisibly returns a list of the current sampler configurations, which are samplerConf reference class objects.}

\item{\code{getMonitors()}}{Prints all current monitors and monitors2

Details: See the initialize() function
            }

\item{\code{getSamplerDefinition(ind)}}{Returns the nimbleFunction definition of an MCMC sampler.

Arguments:

ind: A numeric vector or character vector.  A numeric vector may be used to specify the index of the sampler definition to return, or a character vector may be used to indicate a target node for which the sampler acting on this nodes will be printed. For example, getSamplerDefinition('x[2]') will return the definition of the sampler whose target is model node 'x[2]'.  If more than one sampler function is specified, only the first is returned.

Returns a list object, containing the setup function, run function, and additional member methods for the specified nimbleFunction sampler.}

\item{\code{getSamplers(ind)}}{Returns a list of samplerConf objects.

Arguments:

ind: A numeric vector or character vector.  A numeric vector may be used to specify the indices of the samplerConf objects to return, or a character vector may be used to indicate a set of target nodes and/or variables, for which all samplers acting on these nodes will be returned. For example, getSamplers('x') will return all samplerConf objects whose target is model node 'x', or whose targets are contained (entirely or in part) in the model variable 'x'.  If omitted, then all samplerConf objects in this MCMC configuration object are returned.}

\item{\code{initialize(model, nodes, control = list(), monitors, thin = 1,
  monitors2 = character(), thin2 = 1, useConjugacy = TRUE,
  onlyRW = FALSE, onlySlice = FALSE, multivariateNodesAsScalars = FALSE,
  print = FALSE)}}{Creates a MCMC configuration for a given model.  The resulting object is suitable as an argument to buildMCMC.

Arguments:

model: A NIMBLE model object, created from nimbleModel(...)

nodes: An optional character vector, specifying the nodes for which samplers should be created.
Nodes may be specified in their indexed form, 'y[1, 3]', or nodes specified without indexing will be expanded fully, e.g., 'x' will be expanded to 'x[1]', 'x[2]', etc.
If missing, the default value is all non-data stochastic nodes.
If NULL, then no samplers are added.

control: An optional list of control arguments to sampler functions.  If a control list is provided, the elements will be provided to all sampler functions which utilize the named elements given.
For example, the standard Metropolis-Hastings random walk sampler (sampler_RW) utilizes control list elements 'adaptive', 'adaptInterval', 'scale', 
and also 'targetNode' however this should not generally be provided as a control list element to configureMCMC().
The default values for control list arguments for samplers (if not otherwise provided as an argument to configureMCMC) are in the NIMBLE system option 'MCMCcontrolDefaultList'.

monitors: A character vector of node names or variable names, to record during MCMC sampling.
This set of monitors will be recorded with thinning interval 'thin', and the samples will be stored into the 'mvSamples' object.
The default value is all top-level stochastic nodes of the model -- those having no stochastic parent nodes.

monitors2: A character vector of node names or variable names, to record during MCMC sampling.
This set of monitors will be recorded with thinning interval 'thin2', and the samples will be stored into the 'mvSamples2' object.
The default value is an empty character vector, i.e. no values will be recorded.

thin: The thinning interval for 'monitors'.  Default value is one.

thin2: The thinning interval for 'monitors2'.  Default value is one.

useConjugacy: A logical argument, with default value TRUE.  If specified as FALSE, then no conjugate samplers will be used, even when a node is determined to be in a conjugate relationship.

onlyRW: A logical argument, with default value FALSE.  If specified as TRUE, then Metropolis-Hastings random walk samplers will be assigned for all non-terminal continuous-valued nodes nodes. Discrete-valued nodes are assigned a slice sampler, and terminal nodes are assigned a posterior_predictive sampler.

onlySlice: A logical argument, with default value FALSE.  If specified as TRUE, then a slice sampler is assigned for all non-terminal nodes. Terminal nodes are still assigned a posterior_predictive sampler.

multivariateNodesAsScalars: A logical argument, with default value FALSE.  If specified as TRUE, then non-terminal multivariate stochastic nodes will have scalar samplers assigned to each of the scalar components of the multivariate node.  The default value of FALSE results in a single block sampler assigned to the entire multivariate node.  Note, multivariate nodes appearing in conjugate relationships will be assigned the corresponding conjugate sampler (provided useConjugacy == TRUE), regardless of the value of this argument.

print: A logical argument, specifying whether to print the ordered list of default samplers.}

\item{\code{printSamplers(ind)}}{Prints details of the MCMC samplers.

Arguments:

ind: A numeric vector or character vector.  A numeric vector may be used to specify the indices of the samplers to print, or a character vector may be used to indicate a set of target nodes and/or variables, for which all samplers acting on these nodes will be printed. For example, printSamplers('x') will print all samplers whose target is model node 'x', or whose targets are contained (entirely or in part) in the model variable 'x'.  If omitted, then all samplers are printed.}

\item{\code{removeSamplers(ind, print = FALSE)}}{Removes one or more samplers from an MCMCconf object.

Arguments:

ind: A numeric vector or character vector specifying the samplers to remove.  A numeric vector may specify the indices of the samplers to be removed.  Alternatively, a character vector may be used to specify a set of model nodes and/or variables, and all samplers whose 'target' is among these nodes will be removed.  If omitted, then all samplers are removed.

print: A logical argument, default value FALSE, specifying whether to print the current list of samplers once the removal has been done.}

\item{\code{resetMonitors()}}{Resets the current monitors and monitors2 lists to nothing.

Details: See the initialize() function
            }

\item{\code{setSamplers(ind, print = FALSE)}}{Sets the ordering of the list of MCMC samplers.

Arguments:

ind: A numeric vector or character vector.  A numeric vector may be used to specify the indicies for the new list of MCMC samplers, in terms of the current ordered list of samplers.
For example, if the MCMCconf object currently has 3 samplers, then the ordering may be reversed by calling MCMCconf$setSamplers(3:1), or all samplers may be removed by calling MCMCconf$setSamplers(numeric(0)).

Alternatively, a character vector may be used to specify a set of model nodes and/or variables, and the sampler list will modified to only those samplers acting on these target nodes.

As another alternative, a list of samplerConf objects may be used as the argument, in which case this ordered list of samplerConf objects will define the samplers in this MCMC configuration object, completely over-writing the current list of samplers.  No checking is done to ensure the validity of the contents of these samplerConf objects; only that all elements of the list argument are, in fact, samplerConf objects.

print: A logical argument, default value TRUE, specifying whether to print the new list of samplers.}

\item{\code{setThin(thin, print = TRUE)}}{Sets the value of thin.

Arguments:

thin: The new value for the thinning interval 'thin'.

print: A logical argument, specifying whether to print all current monitors.

Details: See the initialize() function
            }

\item{\code{setThin2(thin2, print = TRUE)}}{Sets the value of thin2.

Arguments:

thin2: The new value for the thinning interval 'thin2'.

print: A logical argument, specifying whether to print all current monitors.

Details: See the initialize() function
            }
}}
\examples{
code <- nimbleCode({
 mu ~ dnorm(0, 1)
 x ~ dnorm(mu, 1)
})
Rmodel <- nimbleModel(code)
conf <- configureMCMC(Rmodel)
conf$setSamplers(1)
conf$addSampler(target = 'x', type = 'slice', control = list(adaptInterval = 100))
conf$addMonitors('mu')
conf$addMonitors2('x')
conf$setThin(5)
conf$setThin2(10)
conf$getMonitors()
conf$printSamplers()
}
\author{
Daniel Turek
}
\seealso{
\link{configureMCMC}
}

