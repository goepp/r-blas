library(Matrix)
library(tidyverse)

## What libraries I am using
sessionInfo()[c("BLAS", "LAPACK")]
## Or (equivalently:)
La_library()
extSoftVersion()["BLAS"]

## Adjacency of sparse graph
library(igraph)
set.seed(123)
graph <- sample_gnm(100, 100)
igraph::edge.attributes(graph)
adj <- as_adj(graph)

image(adj)
