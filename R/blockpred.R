.ramclustR.blockpred <- function(data1, data2, times, sr=NULL, st=NULL, maxt=NULL, maxt_enforce=FALSE, blocksize=2000,
                               timeEnv = environment())
  {
    ##establish some constants for downstream processing
    n<-ncol(data1)
    vlength<-(n*(n-1))/2
    nblocks<-floor(n/blocksize)
    
    ##make list of all row and column blocks to evaluate
    eval1<-expand.grid(0:nblocks, 0:nblocks)
    names(eval1)<-c("j", "k") #j for cols, k for rows
    eval1<-eval1[which(eval1[,"j"]<=eval1[,"k"]),] #upper triangle only
    bl<-nrow(eval1)
    cat('\n', paste("Evaluating blocks to process: nblocks = ", bl))
    
    blockTest <-function(bl, env)  {
      j<-eval1[bl,"j"]  #columns
      k<-eval1[bl,"k"]  #rows
      startc<-min((1+(j*blocksize)), n)
      if ((j+1)*blocksize > n) {
        stopc<-n} else {
          stopc<-(j+1)*blocksize}
      startr<-min((1+(k*blocksize)), n)
      if ((k+1)*blocksize > n) {
        stopr<-n} else {
          stopr<-(k+1)*blocksize}
      if(startc<=startr) { 
        mint<-min(abs(outer(range(times[startr:stopr]), range(times[startc:stopc]), FUN="-")))
        if(mint<=maxt) {
          return(TRUE)
        }
        else
          return(FALSE)
      }
      else
        return(FALSE)
    }
    blocks <- sapply(1:bl, function(bl) blockTest(bl))
    return(blocks)
}

.ramclustR.blockconvert <- function(blocks)
{
  cat("Converting blocks...\n")
  blocks.mat <- lapply(blocks, function(bl)
    {
    bl <- as.data.frame.table(bl)
    bl$Var1 <- as.integer(as.character(bl$Var1))
    bl$Var2 <- as.integer(as.character(bl$Var2))
    bl <- bl[bl$Freq < 1,]
    bl <- bl[bl$Var1 > bl$Var2,]
    list(linkmat = as.matrix(bl[,c("Var2", "Var1")]),
         simcol = as.numeric(bl[,"Freq"]))
  })
  cat("Blocks converted to linkage matrix form\n")
  length.bl <- unlist(lapply(blocks.mat, function(bl) length(bl$simcol)))
  length.tot <- sum(length.bl)
  startpos <- cumsum(c(0, length.bl)) + 1
  linkmat <- matrix(0L, nrow=length.tot, ncol=2)
  simcol <- numeric(length.tot)
  weights <- rep(1L, length.tot)
  
  for(i in seq_along(length.bl))
  {
    linkmat[seq.int(startpos[[i]], length = length.bl[[i]]), ] <- blocks.mat[[i]]$linkmat
    simcol[seq.int(startpos[[i]], length = length.bl[[i]])] <- blocks.mat[[i]]$simcol
  }
  
  list(linkmat = linkmat, sim = simcol, weights = weights)
}

