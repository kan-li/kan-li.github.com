////////////////////////////////////////////////////////////
// 11 1 2016
// Kan Li
//
// This file contains Stan model for inference part of 
// Dynamic Predictions in Bayesian Functional Joint Models 
// for Longitudinal and Time-to-Event Data
////////////////////////////////////////////////////////////
 
 
 data {
  int<lower=0> I; // Number of subjects in training data 	
  int<lower=0> obs_long; // Number of observations
  int subj_long[obs_long];  // Subject index for each observation
  real Y[obs_long];  
  real X[obs_long];
  real W[I];
  int Kx;  // Number of FPC score
  int KB;  // Number of knots for B-spline
  vector[Kx] AX[I]; // FPC score for functional predictor gX
  vector[Kx] AW[I]; // FPC score for functional predictor gW
  real<lower=0> time[I];  // Survival time
  int<lower=0> event[I];  // Censoring indicator
  matrix[Kx, KB] M_matX;  // \int phi(s)psi(s) ds
  matrix[Kx, KB] M_matW;  //
}

parameters {
  vector[2] beta;
  vector[KB] BX;
  real b[I];
  real gamma;
  vector[KB] BW;
  real alpha;
  real logscale;
  real tau_b;
  real tau_Y;
  real sigma_BX;
  real sigma_BW;
}

transformed parameters {
  real sigma_b;
  real sigma_Y;
  real sigma2_b;
  real sigma2_Y;
  real tau_BX;
  real tau_BW;
	
  vector[KB] MxGamX;
  vector[KB] MxGamW;

  vector[I] etaX; // estimated \int gX(s)BX(s) ds
  vector[I] etaW; // estimated \int gW(s)B(s) ds
  real mu[obs_long];
	
  sigma_b <- pow(tau_b, -0.5);
  sigma_Y <- pow(tau_Y, -0.5);
  sigma2_b <- pow(tau_b, -1);
  sigma2_Y <- pow(tau_Y, -1);
  sigma_BX <- pow(tau_BX, -0.5);
  sigma_BW <- pow(tau_BW, -0.5);
 
  // construct the functional components in the model
  MxGamX <- M_matX *BX ;
  MxGamW <- M_matW *BW ;
  	
  for(i in 1:I){
    etaX[i] <- MxGamX' * AX[i];
    etaW[i] <- MxGamW' * AW[i];
  }
  
  // construct the unobserved true trajectory
  for (ob in 1:obs_long){
    mu[ob] <- beta[1] + X[ob]*beta[2] + etaX[subj_long[ob]] + b[subj_long[ob]];
  }
}

model {
  real h[I];
  real S[I];
  real LL[I];
  
  // construct random effect
  b ~ normal(0, sigma_b);
  // construct the longitudinal submodel
  Y ~ normal(mu, sigma_Y);
  
  // construct the survival submodel
  for(i in 1:I){  
    h[i] <- exp(logscale+gamma*W[i] + etaW[i] + alpha*(beta[1] + 
	    beta[2]*time[i] + etaX[i] +b[i]));
    S[i] <- exp(-exp(logscale+gamma*W[i] + etaW[i] + alpha*(beta[1] + etaX[i] + b[i]))*
	    (exp(alpha*beta[2]*time[i])-1)/(alpha*beta[2]));
    LL[i] <- log(pow(h[i],event[i])*S[i]); 
  }
  
  increment_log_prob(LL);
  
  
  // construct the priors
  beta ~ normal(0,10);
  gamma ~ normal(0,10);

  BX[1] ~ normal(0, sigma_BX);
  BW[1] ~ normal(0, sigma_BW);
  for(p in 2:KB){
    BX[p] ~ normal(BX[p-1], sigma_BX);
    BW[p] ~ normal(BW[p-1], sigma_BW);
  }
  
  alpha ~ normal(0,10);
  logscale ~ normal(0, 10);
  tau_Y ~ gamma(0.01,0.01);
  tau_b ~ gamma(0.01,0.01);
  
  tau_BX ~ gamma(0.01,0.01);
  tau_BW ~ gamma(0.01,0.01);

}