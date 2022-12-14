#' Compute matrix with pseudo-validation set
#'
#' @param X
#' matrix with calibration set (IxJ)
#' @param ncomp
#' number of components for PCA decomposition
#' @param nseg
#' number of segments in cross-validation
#' @param scale
#' logical, standardize columns of X prior to decompositon or not
#'
#' @details
#' This is the old (original) version of PCV algorithm for PCA models. Use \code{\link{pcvpca}}
#' instead. Ane check project web-site for details: https://github.com/svkucheryavski/pcv
#'
#' The method computes pseudo-validation matrix Xpv, based on PCA decomposition of calibration set X
#' and systematic (venetian blinds) cross-validation. It is assumed that data rows are ordered
#' correctly, so systematic cross-validation can be applied
#'
#' @return
#' Pseudo-validation matrix (IxJ)
#'
#' @importFrom stats sd
#'
#' @export
pcv <- function(X, ncomp = min(round(nrow(X)/nseg) - 1, col(X), 20), nseg = 4, scale = FALSE) {

   # keep names if any
   attrs <- attributes(X)

   mX <- apply(X, 2, mean)
   sX <- if (scale) apply(X, 2, sd) else rep(1, ncol(X))

   # autoscale the calibration set
   X <- scale(X, center = mX, scale = sX)

   # create a global model
   P <- svd(X)$v[, seq_len(ncomp), drop = FALSE]

   # create matrix with indices for cross-validation, so
   # each column is number of rows to be taken as local validation set
   # in corresponding segment
   ind <- matrix(seq_len(nrow(X)), ncol = nseg, byrow = TRUE)

   # prepare empty matrix for pseudo-validation set
   Xpv <- matrix(0, nrow(X), ncol(X))
   a <- NULL

   # cv-loop
   for (k in seq_len(nseg)) {

      # split data to calibration and validation
      X.c <- X[-ind[, k], , drop = FALSE]
      X.k <- X[ ind[, k], , drop = FALSE]

      # get loadings for local model and rotation matrix between global and local models
      P.k <- svd(X.c, nv = ncomp)$v[, seq_len(ncomp), drop = FALSE]

      # correct direction of loadings for local model
      a <- acos(colSums(P * P.k)) < pi / 2
      P.k <- P.k %*% diag(a * 2 - 1, ncol(P), ncol(P))

      # get rotation matrix between the PC spaces
      R <- getR(P.k, P)

      # rotate the local validation set and save as a part of Xpv
      Xpv[ind[, k], ] <- tcrossprod(X.k, R)
   }

   # uscenter and unscale the data
   Xpv <- sweep(Xpv, 2, sX, "*")
   Xpv <- sweep(Xpv, 2, mX, "+")

   attributes(Xpv) <- attrs
   return(Xpv)
}

#' Creates rotation matrix to map a set vectors \code{base1} to a set of vectors \code{base2}.
#'
#' @param base1
#' Matrix (JxA) with A orthonormal vectors as columns to be rotated (A <= J)
#' @param base2
#' Matrix (JxA) with A orthonormal vectors as columns, \code{base1} should be aligned with
#'
#' @description
#' In both sets vectors should be orthonormal.
#'
#' @return
#' Rotation matrix (JxJ)
getR <- function(base1, base2) {
   base1 <- as.matrix(base1);
   base2 <- as.matrix(base2);

   R1 <- rotationMatrixToX1(base1[, 1])
   R2 <- rotationMatrixToX1(base2[, 1])

   if (ncol(base1) == 1) {
      R <- t(R2) %*% R1
   } else {
      # Compute bases rotated to match their first vectors to [1 0 0 ... 0]'
      base1_r <- as.matrix(R1 %*% base1)
      base2_r <- as.matrix(R2 %*% base2)

      # Get bases of subspaces of dimension n-1 (forget x1)
      nr <- nrow(base1_r) # equal to nrow(base2_r)
      nc <- ncol(base1_r) # equal to ncol(base2_r)
      base1_rs <- base1_r[2:nr, 2:nc]
      base2_rs <- base2_r[2:nr, 2:nc]

      # Recursevely compute rotation matrix to map subspaces
      Rs <- getR(base1_rs, base2_rs)

      # Construct rotation matrix of the whole space (recall x1)
      M <- diag(1, nr)
      M[2:nr, 2:nr] <- Rs

      R <- crossprod(R2, (M %*% R1))
   }

   return(R);
}

#' Creates a rotation matrix to map a vector x to [1 0 0 ... 0]
#'
#' @param x
#' Vector (sequence with J coordinates)
#'
#' @return
#' Rotation matrix (JxJ)
rotationMatrixToX1 <- function(x) {
   N <- length(x)
   R <- diag(1, N)
   step <- 1
   while (step < N) {
      A <- diag(1, N)
      n <- 1
      while (n <= N - step) {
         r2 <- x[n]^2 + x[n + step]^2
         if (r2 > 0) {
            r <- sqrt(r2)
            pcos <- x[n] / r
            psin <- -x[n + step] / r
            A[n, n] <- pcos
            A[n, n + step] <- -psin
            A[n + step, n] <- psin
            A[n + step, n + step] <- pcos
         }
         n <- n + 2 * step
      }
      step <- 2 * step
      x <- A %*% x
      R <- A %*% R
   }
   return(R)
}



