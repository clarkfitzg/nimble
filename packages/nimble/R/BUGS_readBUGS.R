# code for creating BUGS model from a variety of input formats
# pieces written by Daniel Turek and Christopher Paciorek

BUGSmodel <- function(code, name, constants=list(), dimensions=list(), data=list(), inits=list(), returnModel=FALSE, where=globalenv(), debug=FALSE, check=getNimbleOption('checkModel'), calculate = TRUE) {
    if(missing(name)) name <- deparse(substitute(code))
    if(length(constants) && sum(names(constants) == ""))
      stop("BUGSmodel: 'constants' must be a named list")
    if(length(dimensions) && sum(names(dimensions) == ""))
      stop("BUGSmodel: 'dimensions' must be a named list")
    if(length(data) && sum(names(data) == ""))
        stop("BUGSmodel: 'data' must be a named list")
    if(any(!sapply(data, is.numeric)))
        stop("BUGSmodel: elements of 'data' must be numeric and cannot be data frames")
     ## constantLengths <- unlist(lapply(constants, length))
    ## if(any(constantLengths > 1)) {
    ##     iLong <- which(constantLengths > 1)
    ##     message(paste0('Constant(s) ', paste0(names(constants)[iLong], sep=" ", collapse = " "), ' are non-scalar and will be handled as inits.'))
    ##     inits <- c(inits, constants[iLong])
    ##     constants[iLong] <- NULL
    ## }
    md <- modelDefClass$new(name = name)
    if(nimbleOptions('verbose')) message("defining model...")
    md$setupModel(code=code, constants=constants, dimensions=dimensions, debug=debug)
    if(!returnModel) return(md)
    # move any data lumped in 'constants' into 'data' for
    # backwards compatibility with JAGS/BUGS
    if(debug) browser()
    vars <- names(md$varInfo) # varNames contains logProb vars too...
    dataVarIndices <- names(constants) %in% vars & !names(constants) %in% names(data)  # don't overwrite anything in 'data'
    if(sum(names(constants) %in% names(data)))
        warning("BUGSmodel: found the same variable(s) in both 'data' and 'constants'; using variable(s) from 'data'.\n")
    if(sum(dataVarIndices)) {
        data <- c(data, constants[dataVarIndices])
        cat("Adding", paste(names(constants)[dataVarIndices], collapse = ','), "as data for building model.\n")
    }
    if(nimbleOptions('verbose')) message("building model...")
    model <- md$newModel(data=data, inits=inits, where=where, check=check, calculate = calculate, debug = debug)
    if(nimbleOptions('verbose')) message("model building finished.")
    return(model)
}


#' Create a NIMBLE model from BUGS code
#'
#' processes BUGS model code and optional constants, data, and initial values. Returns a NIMBLE model or model definition.
#'
#' @param code code for the model in the form returned by \link{nimbleCode} or (equivalently) \code{quote}
#' @param constants named list of constants in the model.  Constants cannot be subsequently modified. For compatibility with JAGS and BUGS, one can include data values with constants and \code{nimbleModel} will automatically distinguish them based on what appears on the left-hand side of expressions in \code{code}.
#' @param data named list of values for the data nodes.  Data values can be subsequently modified.  Providing this argument also flags nodes as having data for purposes of algorithms that inspect model structure. Values that are NA will not be flagged as data.
#' @param inits named list of starting values for model variables. Unlike JAGS, should only be a single list, not a list of lists.
#' @param dimensions named list of dimensions for variables.  Only needed for variables used with empty indices in model code that are not provided in constants or data.
#' @param returnDef logical indicating whether the model should be returned (FALSE) or just the model definition (TRUE).
#' @param where argument passed to \code{setRefClass}, indicating the environment in which the reference class definitions generated for the model and its modelValues should be created.  This is needed for managing package namespace issues during package loading and does not normally need to be provided by a user.
#' @param debug logical indicating whether to put the user in a browser for debugging.  Intended for developer use.
#' @param check logical indicating whether to check the model object for missing or invalid values.  Default is given by the NIMBLE option 'checkModel', see help on \code{nimbleOptions} for details.
#' @param calculate logical indicating whether to run \code{calculate} on the model after building it; this will calculate all deterministic nodes and logProbability values given the current state of all nodes. Default is TRUE. For large models, one might want to disable this, but note that deterministic nodes, including nodes introduced into the model by NIMBLE, may be \code{NA}. 
#' @param name optional character vector giving a name of the model for internal use.  If omitted, a name will be provided.
#' @author NIMBLE development team
#' @export
#' @details
#' See the User Manual or \code{help(modelBaseClass)} for information about manipulating NIMBLE models created by \code{nimbleModel}, including methods that operate on models, such as \code{getDependencies}.
#'
#' The user may need to provide dimensions for certain variables as in some cases NIMBLE cannot automatically determine the dimensions and sizes of variables. See the User Manual for more information.
#'
#' As noted above, one may lump together constants and data (as part of the \code{constants} argument (unlike R interfaces to JAGS and BUGS where they are provided as the \code{data} argument). One may not provide lumped constants and data as the \code{data} argument.
#'
#' For variables that are a mixture of data nodes and non-data nodes, any values passed in via \code{inits} for components of the variable that are data will be ignored. All data values should be passed in through \code{data} (or \code{constants} as just discussed).
#' @examples
#' code <- nimbleCode({
#'     x ~ dnorm(mu, sd = 1)
#'     mu ~ dnorm(0, sd = prior_sd)
#' })
#' constants = list(prior_sd = 1)
#' data = list(x = 4)
#' Rmodel <- nimbleModel(code, constants = constants, data = data)
nimbleModel <- function(code, constants=list(), data=list(), inits=list(), dimensions=list(), returnDef = FALSE, where=globalenv(), debug=FALSE, check=getNimbleOption('checkModel'), calculate = TRUE, name)
    BUGSmodel(code, name, constants, dimensions, data, inits, returnModel = !returnDef, where, debug, check, calculate)

#' Turn BUGS model code into an object for use in \code{nimbleModel} or \code{readBUGSmodel}
#'
#' Simply keeps model code as an R call object, the form needed by \link{nimbleModel} and optionally usable by \link{readBUGSmodel}
#'
#' @param code expression providing the code for the model
#' @author Daniel Turek
#' @export
#' @details It is equivalent to use the R function \code{quote}.  \code{nimbleCode} is simply provided as a more readable alternative for NIMBLE users not familiar with \code{quote}.
#' @examples
#' code <- nimbleCode({
#'     x ~ dnorm(mu, sd = 1)
#'     mu ~ dnorm(0, sd = prior_sd)
#' })
nimbleCode <- function(code) {
  code <- substitute(code)
  return(code)
}


BUGScode <- nimbleCode

processVarBlock <- function(lines) {
  # processes a var block from a BUGS file, determining variable names, dimensions, and sizes
  # at this point, sizes may have unevaluated variables in them

  # helper functions
  getDim <- function(vec) {
    if(length(vec) > 1)
      return(length(strsplit(vec[2], ";")[[1]])) else return(0)
  }

  getSize <- function(vec) {
    if(length(vec) > 1)
      return(strsplit(vec[2], ";"))  else return("0")
  }

  lines <- gsub("#.*", "", lines)
  lines <- gsub(";", "", lines)
  lines <- gsub("[[:space:]]", "", lines)
  lines <- paste(lines, collapse = "")
  # replace commas in brackets so can split variables
  chars <- strsplit(lines, integer(0))[[1]]
  nch <- length(chars)
  inBrackets <- FALSE
  for(i in seq_len(nch)) {
    if(inBrackets && chars[i] == ",")
      chars[i] = ";"
    if(chars[i] == "[") inBrackets <- TRUE
    if(chars[i] == "]") inBrackets <- FALSE
  }
  lines <- paste(chars, collapse = "")
  lines <- gsub("\\]", "", lines)

  pieces <- unlist(strsplit(lines, ","))
  pieces <- strsplit(pieces, "\\[")
  # variable names are in front of '[' (if there is an '[')
  varNames <- sapply(pieces, "[[", 1)
  dim <- sapply(pieces, getDim)
  size <- sapply(pieces, getSize)
  names(dim) <- varNames
  names(size) <- varNames
  return(list(varNames = varNames, dim = dim, size = size))
}

processModelFile <- function(fileName) {
  # processes a BUGS model file (.bug), splitting into var, data, and code blocks

  codeLines <- readLines(fileName)
  # extract lines corresponding to var, data, code blocks
  # var used for dimension info and data lines sourced in environment of the data input file objects
  codeLines <- paste(codeLines, collapse = "\n")
  codeLines <- gsub("/\\*.*?\\*/", "", codeLines)  # remove C-style comment blocks
  codeLines <- gsub("#.*?\n", "\n", codeLines) # remove R-style comments
  codeLines <- paste("\n", codeLines, collapse = "") # make sure first block occurs after a \n so regex below works ok; this allows me to not mistakenly find 'var', 'data', etc as names of nodes
  varBlockRegEx = "\n\\s*var\\s*(\n*.*?)(\n+\\s*(data|model|const).*)"
  dataBlockRegEx = "\n\\s*data\\s*\\{(.*?)\\}(\n+\\s*(var|model|const).*)"
  modelBlockRegEx = "\n\\s*model\\s*\\{(.*?)\\}\\s*\n+\\s*(var|data|const).*"

  if(length(grep(varBlockRegEx, codeLines))) {
    varLines <- gsub(varBlockRegEx, "\\1", codeLines)
    codeLines <- gsub(varBlockRegEx, "\\2", codeLines)
  } else varLines = NULL
  if(length(grep(dataBlockRegEx, codeLines))) {
    dataLines <- gsub(dataBlockRegEx, "\\1", codeLines)
    codeLines <- gsub(dataBlockRegEx, "\\2", codeLines)
  } else dataLines = NULL
  if(!length(grep(modelBlockRegEx, codeLines))) # model block is last block
    modelBlockRegEx = "model\\s*\\{(.*?)\\}\\s*\n*\\s*$"
  modelLines <- gsub(modelBlockRegEx, "\\1", codeLines)  # removes 'model' and whitespace at begin/end
  modelLines <- paste("{\n", modelLines, "\n}\n", collapse = "")

  return(list(modelLines = modelLines, varLines = varLines, dataLines = dataLines))
}

mergeMultiLineStatements <- function(text) {
    # deals with BUGS syntax that allows multi-line statements where first line appears
    # to be valid full statement (e.g., where '+' starts the 2nd line)
    text <- unlist( strsplit(text, "\n") )
    firstNonWhiteSpaceIndex <- regexpr("[^[:blank:]]", text)
    firstNonWhiteSpaceChar <- substr(text, firstNonWhiteSpaceIndex, firstNonWhiteSpaceIndex)
    mergeUpward <- firstNonWhiteSpaceChar %in% c('+', '-', '*', '/')
    if(length(text) > 1) {
        for(i in seq.int(length(text), 2, by = -1)) {
            if(mergeUpward[i]) {
                text[i-1] <- paste(text[i-1], substring(text[i], firstNonWhiteSpaceIndex[i]) )
            }
        }
    }
    text <- text[!mergeUpward]
    return(text)
}

processNonParseableCode <- function(text) {
    # transforms unparseable code to parseable code
    # at the moment this only deals with T() and I() syntax,
    # transforming to T(<distribution>,<lower>,<upper>)
    text <- gsub("([^~]*)*~(.*?)\\)\\s*([TI])\\s*\\((.*)", "\\1~ \\3(\\2\\), \\4", text)
    return(text)
}

#' Create a NIMBLE BUGS model from a variety of input formats, including BUGS model files
#'
#' \code{readBUGSmodel} processes inputs providing the model and values for constants, data, initial values of the model in a variety of forms, returning a NIMBLE BUGS R model
#'
#' @param model one of (1) a character string giving the file name containing the BUGS model code, with relative or absolute path, (2) an R function whose body is the BUGS model code, or (3) the output of \code{nimbleCode}. If a file name, the file can contain a 'var' block and 'data' block in the manner of the JAGS versions of the BUGS examples but should not contain references to other input data files nor a const block. The '.bug' or '.txt' extension can be excluded.
#'
#' @param data (optional) (1) character string giving the file name for an R file providing the input constants and data as R code [assigning individual objects or as a named list], with relative or absolute path, or (2) a named list providing the input constants and data. If neither is provided, the function will look for a file named 'name_of_model-data' including extensions .R, .r, or .txt.
#'
#' @param inits (optional) (1) character string giving the file name for an R file providing starting values as R code [assigning individual objects or as a named list], with relative or absolute path, or (2) a named list providing the starting values. Unlike JAGS, this should provide a single set of starting values, and therefore if provided as a list should be a simple list and not a list of lists.
#'
#' @param dir (optional) character string giving the directory where the (optional) files are located
#'
#' @param useInits boolean indicating whether to set the initial values, either based on \code{inits} or by finding the '-inits' file corresponding to the input model file
#'
#' @param debug logical indicating whether to put the user in a browser for debugging when \code{readBUGSmodel} calls \code{nimbleModel}.  Intended for developer use.
#'
#' @param returnComponents logical indicating whether to return pieces of model  object without building the model. Default is FALSE.
#'
#' @param check logical indicating whether to check the model object for missing or invalid values.  Default is given by the NIMBLE option 'checkModel', see help on \code{nimbleOptions} for details.
#'
#' @param calculate logical indicating whether to run \code{calculate} on the model after building it; this will calculate all deterministic nodes and logProbability values given the current state of all nodes. Default is TRUE. For large models, one might want to disable this, but note that deterministic nodes, including nodes introduced into the model by NIMBLE, may be \code{NA}. 
#'
#' @author Christopher Paciorek
#'
#' @return returns a NIMBLE BUGS R model
#'
#' @details Note that \code{readBUGSmodel} should handle most common ways of providing information on a model as used in BUGS and JAGS but does not handle input model files that refer to additional files containing data. Please see the BUGS examples provided with JAGS (\url{http://sourceforge.net/projects/mcmc-jags/files/Examples/}) for examples of supported formats. Also, \code{readBUGSmodel} takes both constants and data via the 'data' argument, unlike \code{nimbleModel}, in which these are distinguished. The reason for allowing both to be given via 'data' is for backwards compatibility with the BUGS examples, in which constants and data are not distinguished.
#'
#' @export
#'
#' @examples
#' code <- nimbleCode({
#'     x ~ dnorm(mu, sd = 1)
#'     mu ~ dnorm(0, sd = prior_sd)
#' })
#' data = list(prior_sd = 1, x = 4)
#' model <- readBUGSmodel(code, data = data, inits = list(mu = 0))
#' model$x
#' model[['mu']]
#' model$calculate('x')
readBUGSmodel <- function(model, data = NULL, inits = NULL, dir = NULL, useInits = TRUE, debug = FALSE, returnComponents = FALSE, check = getNimbleOption('checkModel'), calculate = TRUE) {

  # helper function
  doEval <- function(vec, env) {
    out <- rep(0, length(vec))
    if(vec[1] == "0") return(numeric(0))
    for(i in seq_along(vec))
      out[i] <- eval(parse(text = vec[i]), env)
    return(out)
  }

  # process model information

  skip.file.path <- is.null(dir) || (!is.null(dir) && dir == "") ## previously we could have file.path(NULL, ...) and file.path("",...) cases

  modelFileOutput <- modelName <- NULL
  if(is.function(model) || is.character(model)) {
      if(is.function(model)) modelText <- mergeMultiLineStatements(deparse(body(model)))
      if(is.character(model)) {
          if(skip.file.path) modelFile <- model else modelFile <- file.path(dir, model)  # check for "" avoids having "/model.bug" when user provides ""
          modelName <- gsub("\\..*", "", basename(model))
          if(!file.exists(modelFile)) {
              possibleNames <- c(paste0(modelFile, '.bug'), paste0(modelFile, '.txt'))
              fileExistence <- file.exists(possibleNames)
              if(!sum(fileExistence)) {
                  stop("readBUGSmodel: 'model' input does not reference an existing file.")
              } else {
                  if(sum(fileExistence) > 1)
                      warning("readBUGSmodel: multiple possible model files; using .bug file.")
                  modelFile <- possibleNames[which(fileExistence)[1]]
              }
          }
          modelFileOutput <- processModelFile(modelFile)
          modelText <- mergeMultiLineStatements(modelFileOutput$modelLines)
      }

      # deal with T() and I() unparseable syntax
      modelText <- processNonParseableCode(modelText)
      model <- parse(text = modelText)[[1]]
      # note that split lines that are parseable are dealt with by parse()
  }

  if(! class(model) == "{")
    stop("readBUGSmodel: cannot process 'model' input.")

  # process initial values

  if(useInits) {
    initsFile <-  NULL
    if(is.character(inits)) {
      initsFile <- if(skip.file.path) inits else file.path(dir, inits)
      if(!file.exists(initsFile))
        stop("readBUGSmodel: 'inits' input does not reference an existing file.")
    }
    if(is.null(inits)) {
        possibleNames <- paste0(modelName, c("-init.R", "-inits.R", "-init.txt", "-inits.txt", "-init", "inits"))
            ##c(
            ## file.path(dir, paste0(modelName, "-init.R")),
            ## file.path(dir, paste0(modelName, "-inits.R")),
            ## file.path(dir, paste0(modelName, "-init.txt")),
            ## file.path(dir, paste0(modelName, "-inits.txt")),
            ## file.path(dir, paste0(modelName, "-init")),
            ## file.path(dir, paste0(modelName, "-inits")))
        if(!Sys.info()['sysname'] %in% c("Darwin", "Windows")) # UNIX-like is case-sensitive
            possibleNames <- c(possibleNames, paste0(modelName, c('-init.r','-inits.r')))
                      ## possibleNames <- c(possibleNames,
                      ##          file.path(dir, paste0(modelName, "-init.r")),
                      ##          file.path(dir, paste0(modelName, "-inits.r")))
        if(!skip.file.path) possibleNames <- file.path(dir, possibleNames)
        fileExistence <- file.exists(possibleNames)
        if(sum(fileExistence) > 1)
            stop("readBUGSmodel: multiple possible initial value files; please pass as explicit 'inits' argument.")
        if(sum(fileExistence))
            initsFile <- possibleNames[which(fileExistence)[1]]
    }
    if(!is.null(initsFile)) {
      inits <- new.env()
      source(initsFile, inits)
      inits <- as.list(inits)
    }
  } else {
    inits <- NULL
  }
  if(!(is.null(inits) || is.list(inits)))
    stop("readBUGSmodel: invalid input for 'inits'.")

  # process var info
  varInfo <- NULL
  if(!is.null(modelFileOutput) && !is.null(modelFileOutput$varLines))
    varInfo = processVarBlock(strsplit(modelFileOutput$varLines, "\n")[[1]])

  # process data and constants input
  # since data and constants are mixed together in JAGS and BUGS, we take the same approach here (unfortunately)

  dataFile <-  NULL
  if(is.character(data)) {
    dataFile <- if(skip.file.path) data else file.path(dir, data)
    if(!file.exists(dataFile))
      stop("readBUGSmodel: 'data' input does not reference an existing file.")
  }
  if(is.null(data)) {
      possibleNames <- paste0(modelName, c("-data.R", "-data.txt", "data"))
          ## c(
          ##              file.path(dir, paste0(modelName, "-data.R")),
          ##              file.path(dir, paste0(modelName, "-data.txt")),
          ##              file.path(dir, paste0(modelName, "-data")))
    if(!Sys.info()['sysname'] %in% c("Darwin", "Windows")) # UNIX-like is case-sensitive
        possibleNames <- c(possibleNames,
                           paste0(modelName, "-data.r"))
##                         file.path(dir, paste0(modelName, "-data.r")))
      if(!skip.file.path) possibleNames <- file.path(dir, possibleNames)
      fileExistence <- file.exists(possibleNames)
      if(sum(fileExistence) > 1)
          stop("readBUGSmodel: multiple possible initial value files; please pass as explicit 'data' argument.")
      if(sum(fileExistence))
          dataFile <- possibleNames[which(fileExistence)[1]]
  }
  if(!is.null(dataFile)) {
    data <- new.env()
    source(dataFile, data)
  }
  if(is.list(data)) {
    if(length(data) && sum(names(data) == ""))
      stop("readBUGSmodel: 'data' must be a named list")
    data <- list2env(data)  # need as environment for later use
  }

  if(!(is.null(data) || is.environment(data)))
    stop("readBUGSmodel: invalid input for 'data'.")

  if(!is.null(modelFileOutput) && !is.null(modelFileOutput$dataLines)) {
    # process data block in context of data objects
    if(is.null(data))
      data = new.env()

    origVars <- ls(data)

    # create vectors/matrices/arrays for all objects in var block in case data block tries to fill objects
    vars <- varInfo$varNames[varInfo$dim > 0]
    vars <- vars[!(vars %in% ls(data))]
    for(thisVar in vars) {
      dimInfo <- sapply(varInfo$size[[thisVar]], function(x) eval(parse(text = x), envir = data))
      tmp <- 0
      length(tmp) <- prod(dimInfo)
      dim(tmp) <- dimInfo
      assign(thisVar, tmp, envir = data)
    }

    eval(parse(text = modelFileOutput$dataLines), envir = data)
    newVars <- nf_assignmentLHSvars(parse(text = modelFileOutput$dataLines)[[1]])
    data <- as.list(data)[c(origVars, newVars)]
  } else {
    data <- as.list(data)
  }

  # determine dimensions from data list and varInfo
  dims <- lapply(data, dimOrLength, scalarize = TRUE)
  if(!is.null(varInfo)) {
    env <- data
    sizeInfo <- lapply(varInfo$size, doEval, env)
    # by default, use sizes based on actual data objects and ignore info
    # in the var block if it conflicts
    newNames <- names(sizeInfo)[!(names(sizeInfo) %in% names(data))]
    dims[newNames] <- sizeInfo[newNames]
  }

  if(length(dims) && sum(names(dims) == ""))
    stop("readBUGSmodel: something is wrong; 'dims' object is not a named list")

  #returning BUGS parts if we don't want to build model, i.e. rather we want to provide info to MCMCsuite
  if(returnComponents){
  	return( list(modelName = modelName, code = model, dims = dims, data = data, inits = inits) )
  }

  # create R model
  # 'data' will have constants and data, but BUGSmodel is written to be ok with this
  # we can't separate them before building model as we don't know names of nodes in model
  Rmodel <- nimbleModel(code = model, name = ifelse(is.null(modelName), 'model', modelName), constants = data, dimensions = dims, inits = inits, debug = debug, check = check, calculate = calculate)

  # now provide values for data nodes from 'data' list
  if(FALSE) { # now handled within nimbleModel
      dataNodes <- names(data)[(names(data) %in% Rmodel$getVarNames())]
      data <- data[dataNodes]
      names(data) <- dataNodes
      Rmodel$setData(data)

      if(!is.null(inits)) {
          varNames <- names(inits)[names(inits) %in% Rmodel$getVarNames()]
          for(varName in varNames) {
          # check for isData in case a node is a mix of data and non-data and inits are supplied such
          # that they would overwrite the data nodes without this check
              Rmodel[[varName]][!Rmodel$isData(varName)] <- inits[[varName]][!Rmodel$isData(varName)]
          }
      }
  }
  return(Rmodel)
}




#' Get the directory path to one of the classic BUGS examples installed with NIMBLE package
#'
#' NIMBLE comes with some of the classic BUGS examples.  \code{getBUGSexampleDir} looks up the location of an example from its name.
#'
#' @param example The name of the classic BUGS example.
#'
#' @author Christopher Paciorek
#'
#' @return Character string of the fully pathed directory of the BUGS example.
#'
#' @export
getBUGSexampleDir <- function(example){
	dir <- system.file("classic-bugs", package = "nimble")
    vol <- NULL
    if(file.exists(file.path(dir, "vol1", example))) vol <- "vol1"
    if(file.exists(file.path(dir, "vol2", example))) vol <- "vol2"
    if(is.null(vol)) stop("Can't find path to ", example, ".\n")
    dir <- file.path(dir, vol, example)
    return(dir)
}

