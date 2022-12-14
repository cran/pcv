#' Plots heatmap for scaling coefficients obtained when generating PV-set for PCR or PLS
#'
#' @param Xpv
#' PV-set generated by `pcvpcr()` or `pcvpls()`.
#' @param colmap
#' colormap - any with 256 colors.
#' @param lim
#' limits for color map (smallest/largest expected value), centered around 1.
#' @param xlab
#' label for x-axis
#' @param ylab
#' label for y-axis
#' @param ...
#' any other parameters for method `image`
#'
#' @return
#' No return value, just creates a plot.
#'
#' @importFrom graphics image
#' @importFrom grDevices colorRampPalette
#'
#' @export
plotD <- function(Xpv, colmap = colorRampPalette(c("blue", "white", "red"))(256),
   lim = c(-2, 4), xlab = "Components", ylab = "Segments", ...) {

   D <- attr(Xpv, "D")

   if (is.null(D) || !is.matrix(D)) {
      stop("The PV-set does not have attribute with scaling coefficients matrix.")
   }

   image(seq_len(ncol(D)), seq_len(nrow(D)), t(D), zlim = lim,
      breaks = seq(lim[1], lim[2], length.out = 257),
      col = colmap, xlab = xlab, ylab = ylab, ...
   )
}
