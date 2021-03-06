nimbleFinalize <- function(extptr) {
    eval(call('.Call',nimbleUserNamespace$sessionSpecificDll$RNimble_Ptr_ManualFinalizer, extptr))
}

cGetNRow <- function(cMV, compIndex = 1)
{
  nRow = eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getNRow, cMV$componentExtptrs[[compIndex]]))
  return(nRow)
}

## cAddBlank <- function(cMV, addNum)
## {
##   addNum = as.integer(addNum)
##   for(i in 1:length( cMV$componentExtptrs) )
##     status = .Call(getNativeSymbolInfo('addBlankModelValueRows', cMV$dll), cMV$componentExtptrs[[i]], addNum)
##   if(status == FALSE)
##     stop("Error adding rows to ModelValues")
## }

## cCopyVariableRows <- function(cMVFrom, cMVTo, varIndex, rowsFrom = 1:cGetNRow(cMVFrom), rowsTo = 1:cGetNRow(cMVFrom), dll )
## {
##   if(length(varIndex) > 1)
##     stop("cCopyVariableRows only takes on varIndex at a time")
##   rowsFrom = as.integer(rowsFrom )
##   rowsTo = as.integer(rowsTo )
##   if(cMVFrom$extptrCall != cMVTo$extptrCall)
##     stop("ModelValues are not of the same type")
##   fromPtr <- cMVFrom$componentExtptrs[[varIndex]]
##   toPtr <- cMVTo$componentExtptrs[[varIndex]]
##   status = .Call(getNativeSymbolInfo('copyModelValuesElements', dll), fromPtr, toPtr, rowsFrom, rowsTo)
##   if(status == FALSE)
##     stop("Did not correctly copy from one ModelValues to another")
## }

newObjElementPtr = function(rPtr, name, dll){
  eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, rPtr, name))
}

getNimValues <- function(elementPtr, pointDepth = 1, dll){
  if(!inherits(elementPtr, "externalptr"))
    return(NULL)
  eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$Nim_2_SEXP, elementPtr, as.integer(pointDepth)) )
}

setNimValues <- function(elementPtr, values, pointDepth = 1, allowResize = TRUE, dll){
  ptrExp <- substitute(elementPtr)
  storage.mode(values) <- 'numeric'
  if(!inherits(elementPtr, "externalptr"))
    return(NULL)
      jnk = eval(call('.Call',nimbleUserNamespace$sessionSpecificDll$SEXP_2_Nim, elementPtr, as.integer(pointDepth), values, allowResize))
  values
}

setPtrVectorOfPtrs <- function(accessorPtr, contentsPtr, length, dll) {
    if(!inherits(accessorPtr, 'externalptr')) return(NULL)
    if(!inherits(contentsPtr, 'externalptr')) return(NULL)
    if(!is.numeric(length)) return(NULL)
    eval(call('.Call',nimbleUserNamespace$sessionSpecificDll$setPtrVectorOfPtrs, accessorPtr, contentsPtr, as.integer(length)))
    contentsPtr
}

setOnePtrVectorOfPtrs <- function(accessorPtr, i, contentsPtr, dll) {
    if(!inherits(accessorPtr, 'externalptr')) return(NULL)
    if(!is.numeric(i)) return(NULL)
    if(!inherits(contentsPtr, 'externalptr')) return(NULL)
    eval(call('.Call',nimbleUserNamespace$sessionSpecificDll$setOnePtrVectorOfPtrs, accessorPtr, as.integer(i-1), contentsPtr))
    contentsPtr
}

setDoublePtrFromSinglePtr <- function(elementPtr, value, dll) {
    if(!inherits(elementPtr, 'externalptr')) return(NULL)
    if(!inherits(value, 'externalptr')) return(NULL)
    eval(call('.Call',nimbleUserNamespace$sessionSpecificDll$setDoublePtrFromSinglePtr, elementPtr, value))
    value
}

getDoubleValue <- function(elementPtr, pointDepth = 1, dll){
  if(!inherits(elementPtr, "externalptr") )
    return(NULL)
  .Call("double_2_SEXP", elementPtr, as.integer(pointDepth) )
}

setDoubleValue <- function(elementPtr, value,  pointDepth = 1, dll){
  if(!inherits(elementPtr, "externalptr"))
    return(NULL)
  jnk = .Call("SEXP_2_double", elementPtr, as.integer(pointDepth), value)
  value
}

getIntValue <- function(elementPtr, pointDepth = 1, dll){
  if(!inherits(elementPtr, "externalptr") )
    return(NULL)
  .Call("int_2_SEXP", elementPtr, as.integer(pointDepth) )
}

setIntValue <- function(elementPtr, value,  pointDepth = 1, dll){
  if(!inherits(elementPtr, "externalptr"))
    return(NULL)
  jnk = .Call("SEXP_2_int", elementPtr, as.integer(pointDepth), value )
}

getBoolValue <- function(elementPtr, pointDepth = 1, dll){
    if(!inherits(elementPtr, "externalptr") )
        return(NULL)
    .Call("bool_2_SEXP" , elementPtr, as.integer(pointDepth) )
}

setBoolValue <- function(elementPtr, value,  pointDepth = 1, dll){
    if(!inherits(elementPtr, "externalptr"))
        return(NULL)
    jnk = .Call("SEXP_2_bool", elementPtr, as.integer(pointDepth), value )
}

setCharacterValue <- function(elementPtr, value, dll){
    if(!inherits(elementPtr, "externalptr"))
        return(NULL)
    jnk = .Call("SEXP_2_string", elementPtr, value )
}

getCharacterValue <- function(elementPtr, dll){
    if(!inherits(elementPtr, "externalptr") )
        return(NULL)
    .Call("string_2_SEXP" , elementPtr )
}

setCharacterVectorValue <- function(elementPtr, value, dll){
    if(!inherits(elementPtr, "externalptr"))
        return(NULL)
    jnk = .Call("SEXP_2_stringVector" , elementPtr, value )
}

getCharacterVectorValue <- function(elementPtr, dll){
    if(!inherits(elementPtr, "externalptr") )
        return(NULL)
    .Call("stringVector_2_SEXP" , elementPtr)
}
