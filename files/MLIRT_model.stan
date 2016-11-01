data {
  int<lower=0> N_train;
  int<lower=0> obs;
  int subject[obs]; // subject ID
  int<lower=0> K_ordi; // number of ordinal outcomes
  real Y_conti[obs];
  int<lower=0> Y_ordi[obs, K_ordi];
  int<lower=0> n_ordi;
  vector[2] zero;
  real<lower=0> time[obs];   
  int<lower=0> treat[obs];
  int<lower=0> age[obs];
}
parameters {
  vector<lower=-10, upper=10>[3] beta0;
  vector<lower=-10, upper=10>[2] beta1;
  
  vector[2] U[N_train];
  real<lower=0> var1;
  real<lower=0> var2;
  real<lower=-1, upper=1> rho;
  real e[obs];
  real<lower=0> var_e;
  real<lower=0> var_conti;
  
  real a_conti;
  real<lower=0> b_conti;
  real a_ordi_temp;
  real<lower=0> b_ordi_temp;
  vector<lower=0>[n_ordi-2] delta[K_ordi];
}
transformed parameters {
  real<lower=0> sig1;
  real<lower=0> sig2;
  cov_matrix[2] Sigma_U;
  real<lower=0> sd_e;
  real<lower=0> sd_conti;
  vector[n_ordi-1] a_ordi[K_ordi];
  vector<lower=0>[K_ordi] b_ordi;
  real theta[obs];
  real mu_conti[obs];
  real<lower=0, upper=1> psi[obs, K_ordi, n_ordi];
  vector<lower=0, upper=1>[n_ordi] prob_y[obs, K_ordi];
  
  a_ordi[1, 1] <- 0;
  for (l in 2:(n_ordi-1)) a_ordi[1, l] <- a_ordi[1, l-1] + delta[1, l-1] ;
  for (k in 2:K_ordi) {
    a_ordi[k, 1] <- a_ordi_temp;
    for (l in 2:(n_ordi-1)) a_ordi[k, l] <- a_ordi[k, l-1] + delta[k, l-1];
  }
  b_ordi[1] <- 1;
  for (k in 2:K_ordi) b_ordi[k] <- b_ordi_temp;
  
  for (i in 1:obs)
    theta[i] <- beta0[1] + beta0[2]*treat[i] + beta0[3]*age[i] + U[subject[i], 1] + 
    (beta1[1] + beta1[2]*treat[i] + U[subject[i], 2])*time[i] + e[i];
  
  for (i in 1:obs)
    mu_conti[i] <- a_conti + b_conti*theta[i];
  
  for (i in 1:obs) {
    for (k in 1:K_ordi) {
      for (l in 1:(n_ordi-1)) {
        psi[i, k, l] <- inv_logit(a_ordi[k, l] - b_ordi[k]*theta[i]);
      }
      psi[i, k, n_ordi] <- 1;
      
      prob_y[i, k, 1] <- psi[i, k, 1];
      for (l in 2:n_ordi) {prob_y[i, k, l] <- psi[i, k, l] - psi[i, k, l-1];}
    }
  }

  sd_e <- sqrt(var_e);
  sd_conti <- sqrt(var_conti);
  sig1 <- sqrt(var1);
  sig2 <- sqrt(var2);
  Sigma_U[1,1] <- sig1*sig1;
  Sigma_U[1,2] <- rho*sig1*sig2;
  Sigma_U[2,1] <- Sigma_U[1,2];
  Sigma_U[2,2] <- sig2*sig2;
}
model {
  real h[N_train];
  real S[N_train];
  real LL[N_train];
  
  // construct random effects
  U ~ multi_normal(zero, Sigma_U);
  e ~ normal(0, sd_e);
  
  Y_conti ~ normal(mu_conti, sd_conti);
  for (i in 1:obs) {
    for (k in 1:K_ordi) {
      Y_ordi[i, k] ~ categorical(prob_y[i, k]);
    }
  }
  
  // construct the priors
  beta0 ~ normal(0, 10);
  beta1 ~ normal(0, 10);
  var1 ~ inv_gamma(0.01, 0.01);
  var2 ~ inv_gamma(0.01, 0.01);
  rho ~ uniform(-1, 1);
  var_e ~ inv_gamma(0.01, 0.01);
  var_conti ~ inv_gamma(0.01, 0.01);

  for (i in 1:(n_ordi-2)) delta[1, i] ~ normal(0, 10) T[0,] ;
  for (k in 2:K_ordi) {
    b_ordi_temp ~ uniform(0, 10);
    a_ordi_temp ~ normal(0, 10);
    for (i in 1:(n_ordi-2)) delta[k, i] ~ normal(0, 10) T[0,] ;
  }
}
