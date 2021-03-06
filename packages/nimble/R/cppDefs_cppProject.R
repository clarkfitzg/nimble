## Classes for a cppProject
setOldClass("DLLInfo")
setClassUnion("DLLInfoOrNULL", c("NULL", "DLLInfo"))

cppCodeFileClass <- setRefClass('cppCodeFileClass',
                             fields = list(
                                 filename = 'ANY',	#character
                                 includes = 'ANY',	#character
                                 usings = 'ANY',	#character
                                 cppDefs = 'ANY'	#list()
                                 ),
                             methods = list(
                             	initialize = function(...){filename <<- character(); includes <<- character(); usings <<- character(); cppDefs <<- list(); callSuper(...)},

                                 writeIncludes = function(con = stdout()) {
                                     if(length(includes) > 0) writeLines(paste0('#include ', includes), con)
                                     writeLines('#undef eval', con) ## remove R headers' #define eval Rf_eval
                                 },
                                 writeUsings = function(con = stdout()) {
                                     if(length(usings) > 0) writeLines(paste0('using ', usings,';'), con)
                                 },
                                 writeDecs = function(con = stdout()) {
                                     lapply(cppDefs, function(x) {writeLines("", con); writeCode(x$generate(declaration = TRUE), con)})
                                 },
                                 writeDefs = function(con = stdout()) {
                                     lapply(cppDefs, function(x) {writeLines("", con); writeCode(x$generate(declaration = FALSE), con)})
                                 }
                                 )
                             )

cppHfileClass <- setRefClass('cppHfileClass',
                             contains = 'cppCodeFileClass',
                             fields = list(
                                 ifndefName = 'ANY' #'character'
                                 ),
                             methods = list(
                             	initialize = function(...){ifndefName <<- character(); callSuper(...)},
                                 writeFile = function(con = filename, dir = character()) {
                                     if(is.character(con)) {
                                         con <- file.path(dir, paste0(con, '.h'))
                                         zz <- file(con, open = 'w')
                                         on.exit(close(zz))
                                     } else
                                         zz <- con
                                     writeIfndef(zz)
                                     writeIncludes(zz)
                                     writeUsings(zz)
                                     writeDecs(zz)
                                     closeIfndef(zz)
                                     invisible(NULL)
                                 },
                                 writeIfndef = function(con = stdout()) {
                                     writeLines(paste0('#ifndef ',ifndefName,
                                                       '\n#define ',ifndefName),
                                                con)
                                 },
                                 closeIfndef = function(con = stdout()) {
                                     writeLines('#endif', con)
                                 }
                                 )
                             )

cppCPPfileClass <- setRefClass('cppCPPfileClass',
                               contains = 'cppCodeFileClass',
                               fields = list(
                                   ifndefName = 'ANY'
                                   ),
                               methods = list(
                               		initialize = function(...){ifndefName <<- character(); callSuper(...)},
                                   writeFile = function(con = filename, dir = character()) {
                                       if(is.character(con)) {
                                           con <- file.path(dir, paste0(con,'.cpp'))
                                           zz <- file(con, open = 'w')
                                           on.exit(close(zz))
                                       } else
                                           zz <- con
                                       writeIfndef(zz)
                                       writeIncludes(zz)
                                       writeUsings(zz)
                                       writeDefs(zz)
                                       closeIfndef(zz)
                                       invisible(NULL)
                                   },
                                   writeIfndef = function(con = stdout()) {
                                       if(length(ifndefName) > 0)
                                           writeLines(paste0('#ifndef ',ifndefName,
                                                             '\n#define ',ifndefName),
                                                      con)
                                 },
                                   closeIfndef = function(con = stdout()) {
                                       if(length(ifndefName) > 0) writeLines('#endif', con)
                                   }
                                   ))

cppProjectClass <- setRefClass('cppProjectClass',
                               fields = list(
                                   dirName = 'ANY', #'character',
                                   cppDefs = 'ANY', #'list',
                                   dll = 'ANY', #"DLLInfoOrNULL",
                                   outputSOfile = 'ANY',# "character"
                                   Oincludes = 'ANY'
                                   ),
                               methods = list(
                               		initialize = function(...){dirName <<- character(); cppDefs <<- list(); dll <<- NULL; outputSOfile <<- character();callSuper(...)},
                                   addFunction = function(funDef, name, filename) {
                                       if(missing(name)) name <- funDef$name
                                       cppDefs[[name]] <<- funDef
                                         ##XXX This computation doesn't seem to matter. Where is filename stored? ANS: There is a field in the funDef ref class object for it.  could be done in 1 line instead of 2
                                       if(!missing(filename)) {
                                           filename <- Rname2CppName(filename); funDef$filename <- filename
                                       } else {
                                           if(length(funDef$filename)==0) {
                                               filename <- Rname2CppName(name); funDef$filename <- filename
                                           }
                                       }
                                   },
                                   addClass = function(classDef, name, filename, includeNeededTypeDefs = TRUE) {
                                       if(missing(name)) name <- classDef$name
                                       if(!missing(filename)) {
                                           filename <- Rname2CppName(filename)
                                       } else {
                                           if(length(classDef$filename)==0) {
                                               filename <- Rname2CppName(name)
                                           } else {
                                               stop("Error in addClass: Can't determine filename")
                                           }
                                       }
                                       if(includeNeededTypeDefs) {
                                           for(iNTD in classDef$neededTypeDefs) addClass(iNTD, filename = filename)
                                       }
                                       classDef$filename <- filename
                                       cppDefs[[name]] <<- classDef
                                   },
                                   writeFiles = function(filename, con = filename) {
                                       filename <- Rname2CppName(filename)

                                       whichDefs <- which(unlist(lapply(cppDefs, `[[`, 'filename')) == filename)

                                       defs <- cppDefs[whichDefs]
                                       Hincludes <- unlist(lapply(defs, function(x) lapply(x$getHincludes(), function(xx) if(is.character(xx)) xx else paste0('\"',xx$filename,'.h\"'))))
                                       Hincludes <- unique(Hincludes)
                                       CPPincludes <- unlist(lapply(defs, function(x) lapply(x$getCPPincludes(), function(xx) if(is.character(xx)) xx else paste0('\"', xx$filename,'.cpp\"'))))
                                       CPPincludes <- unique(CPPincludes)
                                       selfCPP <- if(is.character(con)) paste0('"', con, '.cpp"') else '"[FILENAME].cpp"'
                                       CPPincludes <- CPPincludes[ CPPincludes != selfCPP ]

                                       ## Eigen must be included before any R header files because they both define "length"
                                       iEigenInclude <- grep("EigenTypedefs", CPPincludes)
                                       if(length(iEigenInclude) > 0) {
                                           CPPincludes <- c(CPPincludes[iEigenInclude], CPPincludes[-iEigenInclude])
                                       }

                                       ## at this point strip out CPPincludes other than EigenTypedefs that have .cpp and gsub .cpp to .o
                                       boolConvertCppIncludeToOinclude <- grepl("\\.cpp", CPPincludes)
                                       if(length(iEigenInclude) > 0) boolConvertCppIncludeToOinclude[1] <- FALSE
                                       Oincludes <<- gsub("\\.cpp", ".o", CPPincludes[boolConvertCppIncludeToOinclude])
                                       CPPincludes <- CPPincludes[!boolConvertCppIncludeToOinclude]

                                       CPPusings <- unlist(lapply(defs, function(x) x$getCPPusings()))
                                       CPPusings <- unique(CPPusings)

                                       ifndefName <- if(is.character(con)) toupper(paste0('__', con)) else '"__IFNDEFNAME"'
                                       cppPieces <- do.call('c', lapply(defs, function(x) x$getDefs()))

                                       hFile <- cppHfileClass(filename = filename,
                                                              includes = Hincludes,
                                                              cppDefs = cppPieces,
                                                              ifndefName = ifndefName)
                                       selfInclude <- if(is.character(con)) paste0('"', con, '.h', '"') else '"[FILENAME].h"'
                                       CPPincludes <- c(CPPincludes, selfInclude) ## selfInclude has to come last because Rinternals.h makes a name conflict with Eigen
                                       
                                     ##  CPPincludes <- c(CPPincludes, ('\"nimble/dynamicRegistrations.cpp\"'))
                                       
                                       cppIfndefName <- paste0(ifndefName,'_CPP')
                                       cppFile <- cppCPPfileClass(filename = filename,
                                                                  includes = CPPincludes,
                                                                  usings = CPPusings,
                                                                  cppDefs= cppPieces,
                                                                  ifndefName = cppIfndefName
                                                                  )

                                       if(is.character(con)) createDir()
                                       hFile$writeFile(con = con, dir = dirName)
                                       cppFile$writeFile(con = con, dir = dirName)
                                   },
                                   writeDynamicRegistrationsDotCpp = function(dynamicRegistrationsCppName, dllName) {
                                       ## this writes dynamicRegistrations.cpp to include <nimble/dynamicRegistrations.h> and
                                       ## then add an R_init function, which must have the name R_init_[outputSOfile]
                                       ##
                                       ## At the moment this step is called immediately before doing R CMD SHLIB
                                       ## And it is only at that stage that the outputSOfile is known, since the SOname includes a time stamp
                                       ## for uniqueness that is created right before R CMD SHLIB.
                                       ## However this content for this file could be integrated into the cppDefs
                                       ## and then automatically written as part of writeFiles.  Doing so would require
                                       ## that the SOname be generated earlier, which would probably be fine.
                                       contentLines <- c(
                                            "#include <nimble/dynamicRegistrations.h>",
                                           "",
                                           "extern \"C\"",
                                           paste0("void R_init_", dllName, "(DllInfo *dll) {"),
                                           "  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);",
                                           "}")
                                       writeLines(contentLines, con = dynamicRegistrationsCppName)
                                   },
                                   compileFile = function(names, .useLib = UseLibraryMakevars) {
                                       cppPermList <- c('RcppUtils.cpp',
                                                        'Utils.cpp',
                                                        'NamedObjects.cpp',
                                                        'ModelClassUtils.cpp',
                                                        'accessorClasses.cpp'
                                                        )
                                       if(getNimbleOption('includeCPPdists')) cppPermList <- c(cppPermList, 'dists.cpp', 'nimDists.cpp')

                                       isWindows = (.Platform$OS.type == "windows")

                                       includes <- character()

                                       ## following was before we created libnimble.a as an alternative to libnimble.so/libnimble.dll
                                       ## includes <- if(!.useLib) {
	                               ##                if(isWindows) {
                                       ##                   shortDirname = dirname(shortPathName(sprintf("%s/%s", NimbleCodeDir, cppPermList[1])))
		    		       ##                   sprintf("%s/%s", shortDirname, cppPermList)
                                       ##                } else
                                       ##                   sprintf("%s/%s", normalizePath(NimbleCodeDir, winslash = '/'), cppPermList)
                                       ## 	            } else
                                       ##                 character()

                                       timeStamp <- format(Sys.time(), "%m_%d_%H_%M_%S")

                                       dynamicRegistrationsDllName <- paste0("dynamicRegistrations_", timeStamp)
                                       dynamicRegistrationsCppName <- paste0(dynamicRegistrationsDllName, ".cpp")
                                       
                                       ## mainfiles <- paste(paste(basename(file.path(dirName, paste0(names,'.cpp'))), collapse = ' '), dynamicRegistrationsCppName)
                                       mainfiles <- paste(basename(file.path(dirName, paste0(names,'.cpp'))), collapse = ' ')


				       if(!file.exists(file.path(dirName, sprintf("Makevars%s", if(isWindows) ".win" else ""))) && NeedMakevarsFile) # should reverse the order here in the long term.
				           createMakevars(.useLib = .useLib, dir = dirName)

                                       dllName <- paste0(names[1], "_", timeStamp)
                                       
                                       outputSOfile <<- file.path(dirName, paste0(dllName, .Platform$dynlib.ext))

                                       includes <- c(includes, Oincludes)
                                       SHLIBcmd <- paste(file.path(R.home('bin'), 'R'), 'CMD SHLIB', paste(c(mainfiles, includes), collapse = ' '), '-o', basename(outputSOfile))

                                       cur = getwd()
                                       setwd(dirName)
                                       on.exit(setwd(cur))

                                       showOutput <- getNimbleOption('showCompilerOutput')


                                       if(is.null(nimbleUserNamespace$sessionSpecificDll)) {
                                           writeDynamicRegistrationsDotCpp(dynamicRegistrationsCppName, dynamicRegistrationsDllName)
                                           ssDllName <- file.path(dirName, paste0(dynamicRegistrationsDllName, .Platform$dynlib.ext))
                                           ssdSHLIBcmd <- paste(file.path(R.home('bin'), 'R'), 'CMD SHLIB', dynamicRegistrationsCppName, '-o', basename(ssDllName))
                                           if(!showOutput) {
                                               logFile <- paste0("dynamicRegistrations_", format(Sys.time(), "%m_%d_%H_%M_%S"), ".log")
                                               ssdSHLIBcmd <- paste(ssdSHLIBcmd, ">", logFile)
                                               ## Rstudio will fail to run a system() command with show.output.on.console=FALSE if any output is actually directed to the console. Redirecting it to a file seems to cure this.
                                           }
                                           if(isWindows)
                                               status = system(ssdSHLIBcmd, ignore.stdout = !showOutput, ignore.stderr = !showOutput, show.output.on.console = showOutput)
                                           else
                                               status = system(ssdSHLIBcmd, ignore.stdout = !showOutput, ignore.stderr = !showOutput)
                                           if(status != 0) 
                                               stop(structure(simpleError("Failed to create the shared library"),
                                                              class = c("SHLIBCreationError", "ShellError", "simpleError", "error", "condition")))
                                           nimbleUserNamespace$sessionSpecificDll <- dyn.load(ssDllName, local = TRUE)
                                       }

                                       if(!showOutput) { 
                                           logFile <- paste0(names[1], "_", format(Sys.time(), "%m_%d_%H_%M_%S"), ".log")
                                           SHLIBcmd <- paste(SHLIBcmd, ">", logFile)
                                           ## Rstudio will fail to run a system() command with show.output.on.console=FALSE if any output is actually directed to the console. Redirecting it to a file seems to cure this.
                                       }
                                       
                                       if(isWindows)
                                           status = system(SHLIBcmd, ignore.stdout = !showOutput, ignore.stderr = !showOutput, show.output.on.console = showOutput)
                                       else
                                           status = system(SHLIBcmd, ignore.stdout = !showOutput, ignore.stderr = !showOutput)
				       if(status != 0)
                                          stop(structure(simpleError("Failed to create the shared library"),
                                                         class = c("SHLIBCreationError", "ShellError", "simpleError", "error", "condition")))
                                   },
                                   loadSO = function(name) {
                                       dll <<- dyn.load(getSOName(name, dirName), local = TRUE)
                                   },
                                   unloadSO = function(check = TRUE, force = FALSE) { ## The book-keeping on different names isn't quite connected to here yet.  Instead we just unload dll.
				       if(!is.null(dll)) {
                                           objectNames <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$RNimble_Ptr_CheckAndRunAllDllFinalizers, dll[['handle']], force))
                                           if(length(objectNames) > 0 & check) {
                                               warning(paste0("A DLL to be unloaded has non-zero (", paste(objectNames, collapse = ", "), ") objects that need to be finalized first. ", if(force) "It's objects were cleared and it was unloaded anyway." else "It was not unloaded." ))
                                               browser()
                                               if(!force) return(NULL)
                                           }
                                           status = dyn.unload(dll[["path"]])
                                           dll <<- NULL
                                           status
                                       } else
                                           FALSE
                                   },
                                   getSOName = function(name, dirName = ".") {
                                           return(outputSOfile)
                                       },
                                   createDir = function() {
                                       if(!file.exists(dirName)) dir.create(dirName)
                                   })
                               )

