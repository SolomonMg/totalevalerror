# Minimal hand-DGP for Phase 3 tests. Phase 6 will replace this with the
# package's exported tee_simulate(). Generates Likert-scale data from a
# crossed random-effects DGP with item, prompt, judge effects, item x prompt
# and item x judge interactions, and replicate noise.
make_sim <- function(N = 20, V = 4, M = 2, R = 3,
                     s2_item = 0.30, s2_prompt = 0.05,
                     s2_ip = 0.04, s2_ij = 0.10,
                     s2_replicate = 0.15,
                     judge_means = c(0, 0.10),
                     seed = 1) {
  set.seed(seed)
  alpha   <- stats::rnorm(N, sd = sqrt(s2_item))
  phi     <- stats::rnorm(V, sd = sqrt(s2_prompt))
  ab_ip   <- matrix(stats::rnorm(N * V, sd = sqrt(s2_ip)), N, V)
  ab_ij   <- matrix(stats::rnorm(N * M, sd = sqrt(s2_ij)), N, M)

  grid <- expand.grid(item = seq_len(N), variant = seq_len(V),
                      judge = seq_len(M), rep = seq_len(R))
  grid$y <- with(grid,
    alpha[item] + phi[variant] + ab_ip[cbind(item, variant)] +
      ab_ij[cbind(item, judge)] + judge_means[judge] +
      stats::rnorm(nrow(grid), sd = sqrt(s2_replicate))
  )
  grid
}
