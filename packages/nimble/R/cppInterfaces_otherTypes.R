# A list of the R-wrapped functions in this file is provided, with further explanation below.
# makeCSingleVariableAccessor <- function(rModelPtr, elementName, beginIndex, endIndex)
# resizeCModelAccessors <- function(modelAccessPtr, size)
# populateManyModelVarAccess <- function(fxnPtr, Robject, manyAccessName)
# 
# makeCSingleModelValuesAccessor <- function(rModelValuesPtr, elementName, curRow = 1, beginIndex, endIndex)
# getModelAccessorValues <- function(modelAccessor)
# getModelValuesAccessorValues <- function(modelAccessor)
# setNodeElement <- function(nodePtr, modelElementPtr, nodeElementName)
# newNodeFxnVec <- function(size = 0)
# resizeNodeFxnVec <- function(nodeFxnVecPtr, size)
# addNodeFxn <- function(NVecFxnPtr, NFxnPtr, addAtEnd = TRUE, index = -1)
# removeNodeFxn <- function(NVecFxnPtr, index = 1, removeAll = FALSE)
# newManyVarAccess <- function(size = 0)
# addSingleVarAccess <- function(ManyVarAccessPtr, SingleVarAccessPtr, addAtEnd = TRUE, index = -1)
# removeSingleVarAccess <- function(ManyVarAccessPtr, index, removeAll)
# newManyModelValuesAccess <- function(size)
# addSingleModelValuesAccess <- function(ManyModelValuesAccessPtr, SingleModelValuesAccessPtr, addAtEnd, index)
# removeSingleModelValuesAccess <- function(ManyModelValuesAccessPtr, index, removeAll)

# NumberedObjects 


## makeCSingleVariableAccessor <- function(rModelPtr, elementName, beginIndex, endIndex){
##     .Call("makeSingleVariableAccessor", rModelPtr, elementName, 
##           as.integer(beginIndex), as.integer(endIndex) ) 
## }    
        
#  This function make a single variable accessor. You must provide the model in which
#  the variable resides by rModelPtr. elementName is the name of the variable you would
#  like to access. beginIndex and endIndex are R indices (i.e. first element is 1, not 0)
#  for the begining and ending sequence of flat indices this accessor uses

populateCopierVector <- function(fxnPtr, Robject, vecName, dll) {
    vecPtr <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, fxnPtr, vecName))
    copierVectorObject <- Robject[[vecName]]
    fromPtr <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, fxnPtr, copierVectorObject[[1]]))
    toPtr <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, fxnPtr, copierVectorObject[[2]]))
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$populateCopierVector, vecPtr, fromPtr, toPtr, as.integer(copierVectorObject[[3]]), as.integer(copierVectorObject[[4]])))
}

populateManyModelVarMapAccess <- function(fxnPtr, Robject, manyAccessName, dll) { ## new version
    manyAccessPtr = eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, fxnPtr, manyAccessName))
    cModel <- Robject[[manyAccessName]][[1]]$CobjectInterface
    ## cModel <- Robject[[manyAccessName]]$sourceObject$CobjectInterface ## NEW ACCESSORS 
    if(is(cModel, 'uninitializedField'))
        stop('Compiled C++ model not available; please include the model in your compilation call (or compile it in advance).', call. = FALSE)

    ## intermediate version
    ## mapInfo <- makeMapInfoFromAccessorVector(Robject[[manyAccessName]]) ## slower
    ## if(length(mapInfo) > 0) {
    ##     .Call('populateValueMapAccessors', manyAccessPtr, mapInfo, cModel$.basePtr)
    ## }

    ## fastest version
    ## doing it above way is safe, but
    ##   doing it the following way induces the crashing.
    mapInfo <- makeMapInfoFromAccessorVectorFaster(Robject[[manyAccessName]])
    if(length(mapInfo[[1]]) > 0) {
        eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$populateValueMapAccessorsFromNodeNames, manyAccessPtr, mapInfo[[1]], mapInfo[[2]], cModel$.basePtr))
    }
    
    ## oldest version
    ##if(Robject[[manyAccessName]]$getLength() > 0) { ## NEW ACCESSORS 
        ##.Call('populateValueMapAccessors', manyAccessPtr, Robject[[manyAccessName]]$getMapInfo(), cModel$.basePtr) 
    ##}
}

populateManyModelValuesMapAccess <- function(fxnPtr, Robject, manyAccessName, dll){ ## new version. nearly identical to populateManyModelVarMapAccess
    manyAccessPtr = eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, fxnPtr, manyAccessName))
    ##cModelValues <- Robject[[manyAccessName]]$sourceObject$CobjectInterface ## NEW ACCESSORS
    cModelValues <- Robject[[manyAccessName]][[1]]$CobjectInterface

    ## oldest
    ##.Call('populateValueMapAccessors', manyAccessPtr, Robject[[manyAccessName]]$getMapInfo(), cModelValues$extptr) ## NEW ACCESSORS

    ## intermediate
    ##    .Call('populateValueMapAccessors', manyAccessPtr, makeMapInfoFromAccessorVector(Robject[[manyAccessName]]), cModelValues$extptr) ## slower
        
    ##fastest
    mapInfo <- makeMapInfoFromAccessorVectorFaster(Robject[[manyAccessName]]) ##faster
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$populateValueMapAccessorsFromNodeNames, manyAccessPtr, mapInfo[[1]], mapInfo[[2]], cModelValues$extptr))
}

## addNodeFxn_LOOP <- function(x, nodes, fxnVecPtr, countInf){
##     countInf$count <- countInf$count + 1
##     addNodeFxn(fxnVecPtr, nodes[[x]]$.basePtr, addAtEnd = FALSE, index = countInf$count)
## }

## getFxnVectorPtr <- function(fxnPtr, fxnVecName)
##     .Call('getModelObjectPtr', fxnPtr, fxnVecName)

## populateNodeFxnVec_OLD <- function(fxnPtr, Robject, fxnVecName){
##     fxnVecPtr <- .Call('getModelObjectPtr', fxnPtr, fxnVecName)
##     resizeNodeFxnVec(fxnVecPtr, length(Robject[[fxnVecName]]$nodes))	
##     nodePtrsEnv <- Robject[[fxnVecName]]$model$CobjectInterface$.nodeFxnPointersEnv
##     nil <- .Call('populateNodeFxnVector', fxnVecPtr, Robject[[fxnVecName]]$nodes, nodePtrsEnv)
## }

getNamedObjected <- function(objectPtr, fieldName, dll)
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getModelObjectPtr, objectPtr, fieldName))

inner_populateNodeFxnVec <- function(fxnVecPtr, gids, numberedPtrs, dll)
    nil <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$populateNodeFxnVector_byGID, fxnVecPtr, as.integer(gids), numberedPtrs))

## This is deprecated.  Remove at some point.
populateNodeFxnVec <- function(fxnPtr, Robject, fxnVecName, dll){
    fxnVecPtr <- getNamedObjected(fxnPtr, fxnVecName, dll = dll)
    gids <- Robject[[fxnVecName]]$gids
    numberedPtrs <- Robject[[fxnVecName]]$model$CobjectInterface$.nodeFxnPointers_byGID$.ptr
    
    ## This is not really the most efficient way to do things; eventually 
    ## we want to have nodeFunctionVectors contain just the gids, not nodeNames
    ## gids <- Robject[[fxnVecName]]$model$modelDef$nodeName2GraphIDs(nodes)
	
    inner_populateNodeFxnVec(fxnVecPtr, gids, numberedPtrs, dll = dll)
}

populateNodeFxnVecNew <- function(fxnPtr, Robject, fxnVecName, dll){
    fxnVecPtr <- getNamedObjected(fxnPtr, fxnVecName, dll = dll)
    indexingInfo <- Robject[[fxnVecName]]$indexingInfo
    declIDs <- indexingInfo$declIDs
    rowIndices <- indexingInfo$unrolledIndicesMatrixRows
    if(is.null(Robject[[fxnVecName]]$model$CobjectInterface) || inherits(Robject[[fxnVecName]]$model$CobjectInterface, 'uninitializedField'))
        stop("populateNodeFxnVecNew: error in accessing compiled model; perhaps you did not compile the model used by your nimbleFunction along with or before this compilation of the nimbleFunction?")
    numberedPtrs <- Robject[[fxnVecName]]$model$CobjectInterface$.nodeFxnPointers_byDeclID$.ptr
    
    ## This is not really the most efficient way to do things; eventually 
    ## we want to have nodeFunctionVectors contain just the gids, not nodeNames
    ## gids <- Robject[[fxnVecName]]$model$modelDef$nodeName2GraphIDs(nodes)
	
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$populateNodeFxnVectorNew_byDeclID, fxnVecPtr, as.integer(declIDs), numberedPtrs, as.integer(rowIndices)))
}

populateIndexedNodeInfoTable <- function(fxnPtr, Robject, indexedNodeInfoTableName, dll) {
    iNITptr <- getNamedObjected(fxnPtr, indexedNodeInfoTableName, dll = dll)
    iNITcontent <- Robject[[indexedNodeInfoTableName]]$unrolledIndicesMatrix
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$populateIndexedNodeInfoTable, iNITptr, iNITcontent))
}

# Currently requires: addSingleModelValuesAccess

## makeCSingleModelValuesAccessor <- function(rModelValuesPtr, elementName, curRow = 1, beginIndex, endIndex)
##     .Call("makeSingleModelValuesAccessor", rModelValuesPtr, elementName, 
##           as.integer(curRow), as.integer(beginIndex), as.integer(endIndex) ) 
## #   Same as above but for modelValues instead of variables of a model. Note that the pointer
## #   we are passing now must point to a C modelValues object, not a model. To get a modelValues pointer
## #   from a model, we would have to first call
## #   MVPtr <- getMVPtr(rModelPtr)    (getMVPtr is in BuildInterfaces.R)
## #   Then we can pass MVPtr to this function
## #   Also, this function requires you to select which row you would like to point to via curRow 
## #   (R index, not C++ index)

## getModelAccessorValues <- function(modelAccessor)
##     .Call("getModelAccessorValues", modelAccessor)
## #   This retrieves the values from a modelAccessor. It is very important to note that this is 
## #   for a singleVariableAccessor, NOT a singleModelValuesAccessor

## getModelValuesAccessorValues <- function(modelAccessor)
##     .Call("getMVAccessorValues", modelAccessor)
## #   Same as above, but for singleModelValuesAccessors


## newNodeFxnVec <- function(size = 0) 
##     .Call("newNodeFxnVector", as.integer(size)  ) 
    
#   This creates a new NodeFunctionVector. We can declare the size of the vector of nodeFunctions upon building.
#   The default size is 0, which leads to the simplest way to populate the nodeFunctionVector: by just adding on to the
#   end one at a time (see addNodeFun for more details). However, the simpliest way is also slow: this method
#   is of complexity O(n^2). This maybe be a problem if we have to deal with dynamic dependencies, for example. 
#   The more efficient to populate this is to set the size in advance and populate by index. This is of O(n) complexity,
#   but means we must keep track of the index as we populate and know number of indices necessary in advance

## resizeNodeFxnVec <- function(nodeFxnVecPtr, size)
##     nil <- .Call("resizeNodeFxnVector", nodeFxnVecPtr, as.integer(size) ) 
## #	Resizes a nodeFunctionPointer object

## addNodeFxn <- function(NVecFxnPtr, NFxnPtr, addAtEnd = TRUE, index = -1)
##     nil <- .Call("addNodeFun", NVecFxnPtr, NFxnPtr, as.logical(addAtEnd), as.integer(index) ) 
## #   This function adds a nodeFunction pointer (NFxnPtr) to a vector of nodeFunctions (NVecFxnPtr)
## #   This can either add one on to the end of the vector (by setting addAtEnd = TRUE) or 
## #   can insert the a nodeFunction by index (by setting addAtEnd = FALSE and index = R-index of position)

## removeNodeFxn <- function(NVecFxnPtr, index = 1, removeAll = FALSE)
##     nil <- .Call("removeNodeFun", NVecFxnPtr, as.integer(index), as.logical(removeAll) ) 
## #   This function removes either the nodeFunctionPointer at position index (R-index) or removes all if removeAll = TRUE

## newManyVarAccess <- function(size = 0)
##     .Call("newManyVariableAccessor", as.integer(size) ) 
## #   Same as newNodeFxnVec, but a builds a ManyVariableAccessor rather than a nodeVectorFunction

## addSingleVarAccess <- function(ManyVarAccessPtr, SingleVarAccessPtr, addAtEnd = TRUE, index = -1)
##     nil <- .Call("addSingleVariableAccessor", ManyVarAccessPtr, SingleVarAccessPtr, as.logical(addAtEnd), as.integer(index) )
## #   Same as addNodeFxn, but for adding a SingleModelVariableAccessor to a ManyModelVariablesAccessors

  
## removeSingleVarAccess <- function(ManyVarAccessPtr, index = 1, removeAll = FALSE)
##     nil <- .Call("removeModelVariableAccessor", ManyVarAccessPtr, as.integer(index), as.logical(removeAll) )
#   Same as removeNodeFxn, but for SingleModelVariableAccessors

## newManyModelValuesAccess <- function(size)
##     .Call("newManyModelValuesAccessor", as.integer(size) ) 
## #   Same as newNodeFxnVec, but for ManyModelValuesAccessor

## addSingleModelValuesAccess <- function(ManyModelValuesAccessPtr, SingleModelValuesAccessPtr, addAtEnd, index = - 1)
##     nil <- .Call("addSingleModelValuesAccessor", ManyModelValuesAccessPtr, SingleModelValuesAccessPtr, as.logical(addAtEnd), as.integer(index) ) 
## #   Same as addNodeFxn, but for adding singleModelValuesAccess to ManyModelValuesAccessor

## removeSingleModelValuesAccess <- function(ManyModelValuesAccessPtr, index, removeAll = FALSE)
##     nil <- .Call("removeModelValuesAccessor", ManyModelValuesAccessPtr, as.integer(index), as.logical(removeAll) ) 
#   Same as removeNodeFxn, but for ManyModelValuessAccessor




# NumberedObjects is a reference class which contains a pointer to a C++ object. This C++ object
# stores void pointers. This pointers are indexed by integers and can be accessesed in R via `[` and `[<-`
# However, the intent is that the pointers will actually be accessed more directly in C++ 
# At this time, used to store pointers to nodeFunctions, which will allow for fast
# population of nodeFunctionVectors. They are indexed by graphID's
numberedObjects <- setRefClass('numberedObjects',
                               fields = c('.ptr' = 'ANY', dll = 'ANY'), 
                               methods = list(
                                   initialize = function(dll){
                                       dll <<- dll
                                       .ptr <<- newNumberedObjects(dll)
                                   },
                                   finalize = function() {
                                       nimbleInternalFunctions$nimbleFinalize(.ptr)
                                   },
                                   getSize = function(){
                                       getSize_NumberedObjects(.ptr, dll)
                                   },
                                   resize = function(size){
                                       resize_NumberedObjects(.ptr, size, dll)
                                   }
                               )
                               )

setMethod('[', 'numberedObjects', function(x, i){
    getNumberedObject(x$.ptr, i, x$dll)
})

setMethod('[<-', 'numberedObjects', function(x, i, value){
    assignNumberedObject(x$.ptr, i, value, x$dll)
    return(x)
})



newNumberedObjects <- function(dll){
    ans <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$newNumberedObjects))
    eval(call('.Call',nimbleUserNamespace$sessionSpecificDll$register_numberedObjects_Finalizer, ans, dll[['handle']], "numberedObjects"))
    ans
}

getSize_NumberedObjects <- function(numberedObject, dll){
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getSizeNumberedObjects, numberedObject))
}

resize_NumberedObjects <- function(numberedObject, size, dll){
    nil <- eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$resizeNumberedObjects, numberedObject, as.integer(size)) )
}

assignNumberedObject <- function(numberedObject, index, val, dll){
    if(!is(val, 'externalptr'))
        stop('Attempting to assign a val which is not an externalptr to a NumberedObjects')
    if(index < 1 || index > getSize_NumberedObjects(numberedObject, dll) )
        stop('Invalid index')
    nil <- eval(call('.Call', getNativeSymbolInfo('setNumberedObject', nimbleUserNamespace$sessionSpecificDll), numberedObject, as.integer(index), val))
}

getNumberedObject <- function(numberedObject, index, dll){
    if(index < 1 || index > getSize_NumberedObjects(numberedObject, dll) )
        stop('Invalid index')
    eval(call('.Call', nimbleUserNamespace$sessionSpecificDll$getNumberedObject, numberedObject, as.integer(index)))	
}


## numberedModelValuesAccessors <- setRefClass('numberedModelValuesAccessors',
##                                             fields = c('.ptr' = 'ANY'),
##                                             methods = list(
##                                                 initialize = function(){ 
##                                                     .ptr  <<- .Call('new_SingleModelValuesAccessor_NumberedObjects')
##                                                 },
##                                                 getSize = function(){
##                                                     getSize_NumberedObjects(.ptr)
##                                                 },
##                                                 resize = function(size){
##                                                     resize_NumberedObjects(.ptr, size)
##                                                 }))

## setMethod('[', 'numberedModelValuesAccessors', function(x, i){
##     getNumberedObject(x$.ptr, i)
## })

## setMethod('[<-', 'numberedModelValuesAccessors', function(x, i, value){
##     assignNumberedObject(x$.ptr, i, value)
##     return(x)
## })
		
		
		
## numberedModelVariableAccessors <- setRefClass('numberedModelVariableAccessors',
##                                               fields = c('.ptr' = 'ANY'),
##                                               methods = list(
##                                                   initialize = function(){ 
##                                                       .ptr  <<- .Call('new_SingleModelVariablesAccessor_NumberedObjects')
##                                                   },
##                                                   getSize = function(){
##                                                       getSize_NumberedObjects(.ptr)
##                                                   },
##                                                   resize = function(size){
##                                                       resize_NumberedObjects(.ptr, size)
##                                                   }))

## setMethod('[', 'numberedModelValuesAccessors', function(x, i){
##     getNumberedObject(x$.ptr, i)
## })

## setMethod('[<-', 'numberedModelValuesAccessors', function(x, i, value){
##     assignNumberedObject(x$.ptr, i, value)
##     return(x)
## })
