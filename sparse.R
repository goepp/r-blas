library(Matrix)

# Initialization
set.seed(1)
m <- 8000
p <- 0.05
A <- rsparsematrix(m, m, p) # generate large sparse matrix
x <- rnorm(m)

# Solving linear system
system.time(S1 <- solve(A, x))

# Matrix multiply
system.time(B <- crossprod(A))

# Solving linear system with symmetric positive definite (spd) matrix
system.time(S2 <- solve(B, x))

# Cholesky Factorization (note: class(B) is symmetric)
system.time(C <- Matrix::Cholesky(B)) # similar to `chol`

# Solving linear system with spd matrix after Cholesky decomposition
system.time(S3 <- solve(C, x))

# Schur Decomposition
# Symmetric matrix necessary to use the sparse method
system.time(D <- Schur(B))

