##############################################################
## Section for outputting C++ code from an exprClass object ##
##############################################################

cppOutputCalls <- c(makeCallList(binaryMidOperators, 'cppOutputMidOperator'),
                    makeCallList(binaryMidLogicalOperators, 'cppOutputMidOperator'),
                    makeCallList(binaryOrUnaryOperators, 'cppOutputBinaryOrUnary'),
                    makeCallList(assignmentOperators, 'cppOutputMidOperator'),
                    makeCallList(nonNativeEigenProxyCalls, 'cppOutputNonNativeEigen'),
                    makeCallList(eigProxyCalls, 'cppOutputEigMemberFunction'),
                    makeCallList(eigCalls, 'cppOutputMemberFunction'),
                    makeCallList(c('setSize', 'initialize', 'getPtr', 'dim', 'getOffset', 'strides', 'isMap', 'mapCopy', 'setMap'), 'cppOutputMemberFunction'),
                    makeCallList(eigOtherMemberFunctionCalls, 'cppOutputEigMemberFunctionNoTranslate'),
                    makeCallList(eigProxyCallsExternalUnary, 'cppOutputEigExternalUnaryFunction'),
                    makeCallList(c('startNimbleTimer','endNimbleTimer'), 'cppOutputMemberFunction'),
                    list(size = 'cppOutputSize',
                         'for' = 'cppOutputFor',
                         'if' = 'cppOutputIfWhile',
                         'while' = 'cppOutputIfWhile',
                         '[' = 'cppOutputBracket',
                         mvAccessRow = 'cppOutputBracket',
                         nimSwitch = 'cppOutputNimSwitch',
                         getParam = 'cppOutputGetParam',
                         getBound = 'cppOutputGetBound',
                         '(' = 'cppOutputParen',
                         resize = 'cppOutputMemberFunctionDeref',
                         nfMethod = 'cppOutputNFmethod',
                         nfVar = 'cppOutputNFvar',
                         getsize = 'cppOutputMemberFunctionDeref',
                         getNodeFunctionIndexedInfo = 'cppOutputGetNodeFunctionIndexedInfo',
                         resizeNoPtr = 'cppOutputMemberFunction',
                         cppMemberFunction = 'cppOutputMemberFunctionGeneric',
                         AssignEigenMap = 'cppOutputEigenMapAssign',
                         chainedCall = 'cppOutputChainedCall',
                         template = 'cppOutputTemplate',
                         nimPrint = 'cppOutputCout',
                         nimCat = 'cppOutputCoutNoNewline',
                         return = 'cppOutputReturn',
                         cppPtrType = 'cppOutputPtrType', ## mytype* (needed in templates like myfun<a*>(b)
                         cppDereference = 'cppOutputDereference', ## *(arg)
                         cppMemberDereference = 'cppOutputMidOperator', ## arg1->arg2
                         '[[' = 'cppOutputDoubleBracket',
                         as.integer = 'cppOutputCast',
                         as.numeric = 'cppOutputCast',
                         numListAccess = 'cppOutputNumList',
                         blank = 'cppOutputBlank',
                         callC = 'cppOutputEigBlank', ## not really eigen, but this just jumps over a layer in the parse tree
                         eigBlank = 'cppOutputEigBlank',
                         voidPtr = 'cppOutputVoidPtr'
                         )
                    )
cppOutputCalls[['pow']] <-  'cppOutputPow'
cppMidOperators <- midOperators
cppMidOperators[['%*%']] <- ' * '
cppMidOperators[['cppMemberDereference']] <- '->'
cppMidOperators[['nfVar']] <- '->'
cppMidOperators[['&']] <- ' && '
cppMidOperators[['|']] <- ' || '
for(v in c('$', ':')) cppMidOperators[[v]] <- NULL
for(v in assignmentOperators) cppMidOperators[[v]] <- ' = '

nimCppKeywordsThatFillSemicolon <- c('{','for',ifOrWhile,'nimSwitch')

## In the following list, the names are names in the parse tree (i.e. the name field in an exprClass object)
## and the elements are the name of the function to use to generate output for that name
## e.g. if the parse tree has "dim(A)" (meaning there is an exprClass object with name = "dim", isCall = TRUE, and a single
## argument that is an exprClass object with name = "A" and isName = TRUE)
## then cppOutputMemberFunction will be called, which will generate A.dim()

## Main function for generating C++ output
nimGenerateCpp <- function(code, symTab = NULL, indent = '', showBracket = TRUE, asArg = FALSE) {
    if(is.numeric(code)) return(code)
    if(is.character(code)) return(paste0('\"', gsub("\\n","\\\\n", code), '\"'))
    if(is.null(code)) return('R_NilValue')
    if(is.logical(code) ) return(code)
    if(is.list(code) ) stop("Error generating C++ code, there is a list where there shouldn't be one.  It is probably inside map information.", call. = FALSE)

    if(length(code$isName) == 0) browser()
    if(code$isName) return(exprName2Cpp(code, symTab, asArg))
    if(code$name == '{') {
        iOffset <- as.integer(showBracket)
        ans <- vector('list', length(code$args) + 2*iOffset)
        if(showBracket) ans[[1]] <- paste0(indent, '{')
        newInd <- if(showBracket) paste0(indent, ' ') else indent
        for(i in seq_along(code$args)) {
            oneEntry <- nimGenerateCpp(code$args[[i]], symTab, newInd, FALSE)
            if(code$args[[i]]$isCall) if(!(code$args[[i]]$name %in% nimCppKeywordsThatFillSemicolon)) oneEntry <- pasteSemicolon(oneEntry)
            ans[[i + iOffset]] <- if(showBracket) addIndentToList(oneEntry, newInd) else oneEntry
        }
        if(showBracket) ans[[length(code$args) + 2]] <- paste0(indent, '}')
        return(ans)
    }
    operatorCall <- cppOutputCalls[[code$name]]
    if(!is.null(operatorCall)) return(eval(call(operatorCall, code, symTab)))
    return(cppOutputCallAsIs(code, symTab))
}

exprName2Cpp <- function(code, symTab, asArg = FALSE) {
    if(!is.null(symTab)) {
        sym <- symTab$getSymbolObject(code$name, inherits = TRUE)
        if(!is.null(sym)) return(sym$generateUse(asArg = asArg))
        return(code$name)
    } else {
        return(code$name)
    }
}

cppOutputVoidPtr <- function(code, symTab) {
    paste('static_cast<void *>(&',code$args[[1]]$name,')')
}

cppOutputBlank <- function(code, symTab) NULL

cppOutputEigBlank <- function(code, symTab) {
    paste0('(', nimGenerateCpp(code$args[[1]], symTab), ')')
}


cppOutputNumList <- function(code, symTab) {
    paste0( nimGenerateCpp(code$args[[1]], symTab))
}

cppOutputGetNodeFunctionIndexedInfo <- function(code, symTab) {
    paste0(code$args[[1]]$name,'.info[', code$args[[2]] - 1, ']')
}

cppOutputReturn <- function(code, symTab) {
    if(length(code$args) == 0) {
        return('return')
    }
    cppOutputCallAsIs(code, symTab)
}

cppOutputCout <- function(code, symTab) {
    paste0('_nimble_global_output <<', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab, asArg = TRUE) ), collapse = '<<'), '<<\"\\n\"; nimble_print_to_R(_nimble_global_output)')
}

cppOutputCoutNoNewline <- function(code, symTab) {
    paste0('_nimble_global_output <<', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab, asArg = TRUE) ), collapse = '<<'), '; nimble_print_to_R(_nimble_global_output)')
}

cppOutputChainedCall <- function(code, symTab) {
    firstCall <- nimGenerateCpp(code$args[[1]], symTab)
    ## now similar to cppOutputCallAsIs
    paste0(firstCall, '(', paste0(unlist(lapply(code$args[-1], nimGenerateCpp, symTab, asArg = TRUE) ), collapse = ', '), ')' )
}

cppOutputFor <- function(code, symTab) {
    if(code$args[[2]]$name != ':') stop('Error: for now for loop ranges must be defined with :')
    begin <- nimGenerateCpp(code$args[[2]]$args[[1]], symTab)
    end <- nimGenerateCpp(code$args[[2]]$args[[2]], symTab)
    iterVar <- nimGenerateCpp(code$args[[1]], symTab)
    part1 <- paste0('for(', iterVar ,'=', begin,'; ', iterVar, '<= static_cast<int>(', end, '); ++', iterVar,')')
    part2 <- nimGenerateCpp(code$args[[3]], symTab)
    if(is.list(part2)) {
        part2[[1]] <- paste(part1, part2[[1]])
        return(part2)
    } else {
        return(paste(part1, part2))
    }
}

cppOutputIfWhile <- function(code, symTab) {
    part1 <- paste0(code$name,'(', nimGenerateCpp(code$args[[1]], symTab), ')')
    part2 <- nimGenerateCpp(code$args[[2]], symTab)
    if(is.list(part2)) {
        part2[[1]] <- paste(part1, part2[[1]])
    } else {
        part2 <- list(paste(part1, part2))
    }
    if(length(code$args)==2) return(part2)

    part3 <- nimGenerateCpp(code$args[[3]], symTab)
    if(is.list(part3)) {
        part2[[length(part2)]] <- paste(part2[[length(part2)]], 'else', part3[[1]])
        part3 <- c(part2, part3[-1])
        return(part3)
    } else {
        part2[[length(part2)]] <- paste(part2[[length(part2)]], 'else', part3)
        return(part2)
    }
    stop('Error in cppOutputIf')
}

cppOutputNimSwitch <- function(code, symTab) {
    numChoices <- length(code$args)-2
    if(numChoices <= 0) return('')
    choicesCode <- vector('list', numChoices)
    choiceValues <- code$args[[2]]
    if(length(choiceValues) != numChoices) stop(paste0('number of switch choices does not match number of indices for ',nimDeparse(code)))
    for(i in 1:numChoices) {
        if(code$args[[i+2]]$name != '{')
            bracketedCode <- insertExprClassLayer(code, i+2, '{')
        choicesCode[[i]] <- list(paste0('case ',choiceValues[i],':'), nimGenerateCpp(code$args[[i+2]], symTab, showBracket = FALSE), 'break;')
    }
    ans <- list(paste('switch(',code$args[[1]]$name,') {'), choicesCode, '}')
    ans
}

cppOutputGetParam <- function(code, symTab) {
    ##    return(paste0(code$args[[1]]$name,'.getNodeFunctionPtrs()[0]->getParam_',code$nDim,'D_',code$type,'(', code$args[[2]]$name, ')'))
  ##  iNodeFunction <- if(length(code$args) < 3) 0 else paste(cppMinusOne(nimDeparse(code$args[[3]])))
    if(length(code$args) < 4) {  ## code$args[[3]] is used for the paramInfo that is only used in size processing
        ans <- paste0('getParam_',code$nDim,'D_',code$type,'(',code$args[[2]]$name,',',code$args[[1]]$name,'.getUseInfoVec()[0])')
    } else {
        iNodeFunction <- paste(cppMinusOne(nimDeparse(code$args[[4]])))
        ans <- paste0('getParam_',code$nDim,'D_',code$type,'(',code$args[[2]]$name,',',code$args[[1]]$name,
                      '.getUseInfoVec()[',iNodeFunction,'],', iNodeFunction ,')')
    }
    return(ans)
##    return(paste0('getParam_',code$nDim,'D_',code$type,'(',code$args[[2]]$name,',',code$args[[1]]$name,'.getUseInfoVec()[',iNodeFunction,'])'))
}

cppOutputGetBound <- function(code, symTab) {
    ##    return(paste0(code$args[[1]]$name,'.getNodeFunctionPtrs()[0]->getParam_',code$nDim,'D_',code$type,'(', code$args[[2]]$name, ')'))
  ##  iNodeFunction <- if(length(code$args) < 3) 0 else paste(cppMinusOne(nimDeparse(code$args[[3]])))
    if(length(code$args) < 4) {  ## code$args[[3]] is used for the paramInfo that is only used in size processing
        ans <- paste0('getBound_',code$nDim,'D_',code$type,'(',code$args[[2]]$name,',',code$args[[1]]$name,'.getUseInfoVec()[0])')
    } else {
        iNodeFunction <- paste(cppMinusOne(nimDeparse(code$args[[4]])))
        ans <- paste0('getBound_',code$nDim,'D_',code$type,'(',code$args[[2]]$name,',',code$args[[1]]$name,
                      '.getUseInfoVec()[',iNodeFunction,'],', iNodeFunction ,')')
    }
    return(ans)
##    return(paste0('getParam_',code$nDim,'D_',code$type,'(',code$args[[2]]$name,',',code$args[[1]]$name,'.getUseInfoVec()[',iNodeFunction,'])'))
}

cppOutputEigenMapAssign <- function(code, symTab) {
    useStrides <- length(code$args) > 5
    strideTemplateDec <- if(useStrides) {
        if(!(is.numeric(code$args[[6]]) & is.numeric(code$args[[7]]) ) ) {
            bothStridesDyn <- TRUE
            paste0('EigStrDyn')
        } else {
            bothStridesDyn <- FALSE
            paste0(', Stride<', if(is.numeric(code$args[[6]])) code$args[[6]] else 'Dynamic', ', ', if(is.numeric(code$args[[7]])) code$args[[7]] else 'Dynamic','>')
        }
    } else character()
    strideConstructor <- if(useStrides) {
        paste0(strideTemplateDec, '(', nimGenerateCpp(code$args[[6]], symTab),', ', nimGenerateCpp(code$args[[7]], symTab), ')')
    } else character()
    MapType <- if(!useStrides) {
        paste0('Map< ', code$args[[3]]$name,' >')
    } else {
        if(bothStridesDyn) 'EigenMapStr'
        else paste0('Map< ', code$args[[3]]$name, ', Unaligned, ', strideTemplateDec,' >')
    }
    paste0('new (&', nimGenerateCpp(code$args[[1]], symTab),') ', MapType, '(', paste(c(nimGenerateCpp(code$args[[2]], symTab), nimGenerateCpp(code$args[[4]], symTab), nimGenerateCpp(code$args[[5]], symTab), strideConstructor), collapse = ','), ')')
}

cppOutputSize <- function(code, symTab) {
    ## Windows compiler will give warnings if something.size(), which returns unsigned int, is compared to an int.  Since R has no unsigned int, we cast .size() to int.
    paste0('static_cast<int>(', nimGenerateCpp(code$args[[1]], symTab), '.size())')
}

cppOutputMemberFunction <- function(code, symTab) {
    paste0( nimGenerateCpp(code$args[[1]], symTab), '.', paste0(code$name, '(', paste0(unlist(lapply(code$args[-1], nimGenerateCpp, symTab) ), collapse = ', '), ')' ))
}

cppOutputMemberFunctionGeneric <- function(code, symTab) { ##cppMemberFunction(myfun(myobj, arg1, arg2)) will generate myobj.myfun(arg1, arg2)
    cppOutputMemberFunction(code$args[[1]], symTab)
}

cppOutputEigExternalUnaryFunction <- function(code, symTab) {
    info <-  eigProxyTranslateExternalUnary[[code$name]]
    if(length(info) != 3) stop(paste0("Invalid information entry for outputting eigen version of ", code$name), call. = FALSE)
    paste0( '(', nimGenerateCpp(code$args[[1]], symTab), ').unaryExpr(std::ptr_fun<',info[2],', ',info[3],'>(', info[1], '))')
}

## like cppOutputCallAsIs but using eigProxyTranslate on the name
cppOutputNonNativeEigen <- function(code, symTab) {
    paste0(eigProxyTranslate[code$name], '(', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab, asArg = TRUE) ), collapse = ', '), ')' )
}

cppOutputEigMemberFunction <- function(code, symTab) {
    paste0( '(', nimGenerateCpp(code$args[[1]], symTab), ').', paste0(eigProxyTranslate[code$name], '(', paste0(unlist(lapply(code$args[-1], nimGenerateCpp, symTab) ), collapse = ', '), ')' ))
}

cppOutputEigMemberFunctionNoTranslate <- function(code, symTab) {
    paste0( '(', nimGenerateCpp(code$args[[1]], symTab), ').', paste0(code$name, '(', paste0(unlist(lapply(code$args[-1], nimGenerateCpp, symTab) ), collapse = ', '), ')' ))
}

cppOutputMemberFunctionDeref <- function(code, symTab) {
    paste0( nimGenerateCpp(code$args[[1]], symTab), '->', paste0(code$name, '(', paste0(unlist(lapply(code$args[-1], nimGenerateCpp, symTab) ), collapse = ', '), ')' ))
}

cppOutputNFvar <- function(code, symTab) {
    if(length(code$args) != 2) stop('Error: expecting 2 arguments for operator ',code$name)
    paste0( nimGenerateCpp(code$args[[1]], symTab), '.', code$args[[2]] ) ## No nimGenerateCpp on code$args[[2]] because it should be a string
}

cppOutputNFmethod <- function(code, symTab) {
    if(length(code$args) < 2) stop('Error: expecting at least 2 arguments for operator ',code$name)
    paste0( nimGenerateCpp(code$args[[1]], symTab), '.', code$args[[2]]) ##, ## No nimGenerateCpp on code$args[[2]] because it should be a string
    ## This used to take method args in this argList.  But now they are in a chainedCall
}

cppOutputMidOperator <- function(code, symTab) {
    if(length(code$args) != 2) stop('Error: expecting 2 arguments for operator ',code$name)
    if(is.null(code$caller)) useParens <- FALSE
    else {
        thisRank <- operatorRank[[code$name]]
        callingRank <- if(!is.null(code$caller)) operatorRank[[code$caller$name]] else NULL
        useParens <- FALSE ## default to FALSE - possibly dangerous if we've missed a case
        if(!is.null(callingRank)) {
            if(!is.null(thisRank)) {
                if(callingRank <= thisRank) useParens <- TRUE
            }
        }
    }

    useDoubleCast <- FALSE
    if(code$name == '/') ## cast the denominator to double if it is any numeric or if it is an scalar integer expression
        if(is.numeric(code$args[[2]]) ) useDoubleCast <- TRUE
        else ## We have cases where a integer ends up with type type 'double' during compilation but should be cast to double for C++, so we shouldn't filter on 'integer' types here
            if(identical(code$args[[2]]$nDim, 0)) useDoubleCast <- TRUE

    secondPart <- nimGenerateCpp(code$args[[2]], symTab)
    if(useDoubleCast) secondPart <- paste0('static_cast<double>(', secondPart, ')')

    if(useParens)
        paste0( '(',nimGenerateCpp(code$args[[1]], symTab), cppMidOperators[[code$name]],secondPart,')' )
    else
        paste0( nimGenerateCpp(code$args[[1]], symTab), cppMidOperators[[code$name]],secondPart)
}

cppOutputBinaryOrUnary <- function(code, symTab) {
    if(length(code$args) == 2) return(cppOutputMidOperator(code, symTab))
    cppOutputCallAsIs(code, symTab)
}

cppMinusOne <- function(x) {
    if(is.numeric(x)) return(x-1)
    paste0('(',x,') - 1')
}

cppOutputBracket <- function(code, symTab) {
    brackets <- if(length(code$args) <= 2) c('[',']') else c('(',')')
    paste0( nimGenerateCpp(code$args[[1]], symTab), brackets[1], paste0(unlist(lapply(code$args[-1], function(x) cppMinusOne(nimGenerateCpp(x, symTab) ) ) ), collapse = ', '), brackets[2] )
}

cppOutputDoubleBracket <- function(code, symTab) {
    ## right now the only case is from a functionList, so we'll go straight there.
    cppOutputNimFunListAccess(code, symTab)
}

cppOutputNimFunListAccess <- function(code, symTab) {
    paste0( '(*', nimGenerateCpp(code$args[[1]], symTab), '[', cppMinusOne(nimGenerateCpp(code$args[[2]], symTab) ), '])' )
}

cppOutputParen <- function(code, symTab) {
    paste0('(', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab) ), collapse = ', '), ')' )
}

cppOutputCall <- function(code, symTab) {
    paste0(cppOutputCalls[[code$name]], '(', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab ) ), collapse = ', '), ')' )
}

cppOutputPow <- function(code, symTab) {
    useStaticCase <- if(is.numeric(code$args[[2]]) ) TRUE else identical(code$args[[2]]$nDim, 0)
    if(useStaticCase)
        paste0(exprName2Cpp(code, symTab), '( static_cast<double>(',nimGenerateCpp(code$args[[1]], symTab, asArg = TRUE),'),', nimGenerateCpp(code$args[[2]], symTab, asArg = TRUE),')')
    else
        paste0(exprName2Cpp(code, symTab), '(',nimGenerateCpp(code$args[[1]], symTab, asArg = TRUE),',', nimGenerateCpp(code$args[[2]], symTab, asArg = TRUE),')')
}

cppOutputCallAsIs <- function(code, symTab) {
    paste0(exprName2Cpp(code, symTab), '(', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab, asArg = TRUE) ), collapse = ', '), ')' )
}

cppOutputCast <- function(code, symTab) {
    paste0('static_cast<', cppCasts[[code$name]], '>(', nimGenerateCpp(code$args[[1]], symTab), ')')
}

cppOutputCallWithName <- function(code, symTab, name) {
    paste0(name, '(', paste0(unlist(lapply(code$args, nimGenerateCpp, symTab, asArg = TRUE) ), collapse = ', '), ')' )
}

cppOutputPtrType <- function(code, symTab) {
    paste0( nimGenerateCpp(code$args[[1]], symTab), '*' )
}

cppOutputDereference <- function(code, symTab) {
    cppOutputCallWithName(code, symTab, '*')
}

cppOutputTemplate <- function(code, symTab) {
    paste0(code$args[[1]]$name, '<', paste0(unlist(lapply(code$args[-1], nimGenerateCpp, symTab, asArg = TRUE) ), collapse = ', '), '>' )
}
