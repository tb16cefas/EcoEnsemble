functions{
  /**
   * Rescaling [-1,1] -> [0,1] to make the Beta distribution applicable for correlations
   */
  real As(real Rho){
    return 1/pi() * atan(Rho/sqrt(1-Rho^2))+0.5;
  }

  /**
   * Beta prior for correlation matrices
   */
  real priors_cor_beta(matrix Rho, int N, matrix beta_1, matrix beta_2) {
    real log_prior;
    log_prior =0;
    for (i in 1:(N-1))  {
      for (j in (i+1):N){
        log_prior += beta_lpdf(As(Rho[i,j])|beta_1[i,j],beta_2[i,j]);
      }
    }
    return log_prior;
  }

  /**
   * The Kalman filter - likelihood
   */


  int sq_int(int[] model_num_species, int M){
    int ret = 0;
    for (i in 1:M){
	    ret += model_num_species[i] * model_num_species[i];
	  }
	  return ret;
  }
}
data{
  int <lower=0> N;   // Number of variables
  //int <lower=0> time;// How long the model is run for

  /**
   * Observations
   */
   /*
  vector [N] observations[time];
  cov_matrix [N] obs_covariances;

  /**
  * Simulators
  */

  int<lower=0> M; // number of models
/*
  matrix [time,M+1] observation_times; // times that observations happen
  int<lower=0> model_num_species[M]; // might have to be one
  matrix[sum(model_num_species),N] Ms;  // the Ms -- this assumes that the observations are always the same
  matrix [time ,sum(model_num_species)] model_outputs; // vector of observations from the models
  vector [sq_int(model_num_species, M)] model_covariances; // vector of covariance matrices -- this needs to be checked that the individual matrices are positive definite!
*/

	/**
	 * Prior choice paramters:
	 * These determine the form of the prior parametrisation using an integar representation.
	 * Choices 0,1,2 use a decomposition into a diagonal variance matrix and a correlation matrix,
	 * with inverse-gamma distributions on the variance terms.
	 *      0 - LKJ correlation matrix
	 *      1 - Inverse Wishart correlation matrix
	 *      2 - Beta distributions on correlation matrix entries.
	 *      NOT IMPLEMENTED: 3 - Inverse Wishart covariance matrix
	 *
	 */
	 int<lower=0, upper=3> form_prior_ind_st;
	 int<lower=0, upper=3> form_prior_ind_lt;
	 int<lower=0, upper=3> form_prior_sha_st;


  /**
   * Prior parameters
   */
  //Individual short-term
  vector [N] prior_ind_st_var_a; // shape parameter (alpha) of inverse gamma
	vector [N] prior_ind_st_var_b; // scale parameter (beta) of inverse gamma
	real prior_ind_st_cor_lkj[form_prior_ind_st == 0 ? 1 : 0]; // LKJ shape parameter
  matrix[form_prior_ind_st == 1 ? N : 0, form_prior_ind_st == 1 ? N : 0] prior_ind_st_cor_wish_sigma;//inverse wishart
	real<lower=N-1>	prior_ind_st_cor_wish_nu[form_prior_ind_st == 1 ? 1 : 0]; //inverse wishart
	matrix [form_prior_ind_st == 2 ? N : 0, form_prior_ind_st == 2 ? N : 0] prior_ind_st_cor_beta_1; // alpha shape parameter for Beta distribution
  matrix [form_prior_ind_st == 2 ? N : 0, form_prior_ind_st == 2 ? N : 0] prior_ind_st_cor_beta_2; // beta shape parameter for Beta distribution

  //Individual long-term
  vector [N] prior_ind_lt_var_a ; // shape parameter (alpha) of inverse gamma
  vector [N] prior_ind_lt_var_b ; // scale parameter (beta) of inverse gamma
  real prior_ind_lt_cor_lkj[form_prior_ind_lt == 0 ? 1 : 0]; // LKJ shape parameter
  matrix[form_prior_ind_lt == 1 ? N : 0, form_prior_ind_lt == 1 ? N : 0] prior_ind_lt_cor_wish_sigma;//inverse wishart
	real<lower=N-1>	prior_ind_lt_cor_wish_nu[form_prior_ind_lt == 1 ? 1 : 0]; //inverse wishart
	matrix [form_prior_ind_lt == 2 ? N : 0, form_prior_ind_lt == 2 ? N : 0] prior_ind_lt_cor_beta_1; // alpha shape parameter for Beta distribution
  matrix [form_prior_ind_lt == 2 ? N : 0, form_prior_ind_lt == 2 ? N : 0] prior_ind_lt_cor_beta_2; // beta shape parameter for Beta distribution


	//Shared short-term
	//real<lower=0> prior_sha_st_var_exp; // Scale parameter of exponential
	vector [N] prior_sha_st_var_a ; // shape parameter (alpha) of inverse gamma
  vector [N] prior_sha_st_var_b ; // scale parameter (beta) of inverse gamma
	real prior_sha_st_cor_lkj[form_prior_sha_st == 0 ? 1: 0]; // LKJ shape parameter
	matrix[form_prior_sha_st == 1 ? N: 0,form_prior_sha_st == 1 ? N: 0] prior_sha_st_cor_wish_sigma;//inverse wishart
	real<lower=N-1>	prior_sha_st_cor_wish_nu[form_prior_sha_st == 1 ? 1: 0]; //inverse wishart
	matrix [form_prior_sha_st == 2 ? N: 0,form_prior_sha_st == 2 ? N: 0] prior_sha_st_cor_beta_1; // alpha shape parameter for Beta distribution
  matrix [form_prior_sha_st == 2 ? N: 0,form_prior_sha_st == 2 ? N: 0] prior_sha_st_cor_beta_2; // beta shape parameter for Beta distribution

 //Shared long-term
	vector <lower=0> [N] prior_sha_lt_sd; //sd for prior on error

	//Random walk on y
	vector <lower=0> [N] prior_y_init_mean_sd;
  vector [N] prior_y_init_var_a;
  vector [N] prior_y_init_var_b; // Initial variance of y
  real<lower=N-1>	prior_sigma_t_inv_wish_nu; //inverse wishart
	matrix[N, N] prior_sigma_t_inv_wish_sigma;//inverse wishart

}
parameters{
  /**
   * Simulator discrepancies
   */
  // Individual
  vector <lower=-1,upper=1>[N] ind_st_ar_param[M];
  vector <lower=0>[N] ind_st_var[M];
  corr_matrix [N] ind_st_cor[M];
  vector[N] ind_lt_raw[M];
  vector <lower=0> [N] ind_lt_var;
  corr_matrix [N] ind_lt_cor;
  // Shared
  vector <lower=-1,upper=1>[N] sha_st_ar_param;
  vector <lower=0> [N] sha_st_var;
  corr_matrix [N] sha_st_cor;
  vector [N] sha_lt_raw;

  /**
   * Random walk on y
   */
  cov_matrix [N] SIGMA_t;
  vector [N] y_init_mean;
  vector <lower=0> [N] y_init_var;
}
transformed parameters{
  matrix [N,N] SIGMA_x[M];
  vector [N] ind_st_sd[M];
  vector [N] sha_lt = prior_sha_lt_sd .* sha_lt_raw;
  vector [N] ind_lt[M];
  //JM 28/02/22: Initing with their values.
  //vector [N] ind_lt_sd;
  //matrix [N,N] ind_lt_covar;
  //matrix [N,N] ind_lt_cov_cholesky;
  vector [N] ind_lt_sd = sqrt(ind_lt_var);
  matrix [N,N] ind_lt_covar = diag_post_multiply(diag_pre_multiply(ind_lt_sd,ind_lt_cor),ind_lt_sd);
  matrix [N,N] ind_lt_cov_cholesky = cholesky_decompose(ind_lt_covar);


  vector [(M+2) * N] x_hat = append_row(y_init_mean,rep_vector(0.0,N * (M + 1)));
  matrix [(M+2) * N,(M+2) * N] SIGMA_init = rep_matrix(0,(M+2) * N,(M+2) * N );
  //JM 28/02/22: Reparametrising the shared short-term variances by inverse gammas
  //matrix[N , N] SIGMA_mu = diag_post_multiply(diag_pre_multiply(sha_st_var,sha_st_cor),sha_st_var);
  vector [N] sha_st_sd = sqrt(sha_st_var);
  matrix [N,N] SIGMA_mu = diag_post_multiply(diag_pre_multiply(sha_st_sd, sha_st_cor), sha_st_sd);

  /**
  *  Kalman filter parameters:
  *  In each case, the ordering to be passed through to the Kalman Filter is:
  *  (1) Observations (2) Consensus (3) Models
  *     [if (1) is available, otherwise this is ignored]
  *
  */
  matrix[(M+2) * N , (M+2) * N] SIGMA = rep_matrix(0,(M+2) * N,(M+2) * N );
  vector[(M+2) * N ] lt_discrepancies;
  vector[(M+2) * N] AR_params;

  //SIGMA
  SIGMA[1:N, 1:N ] = SIGMA_t;
  SIGMA[(N + 1):(2*N), (N + 1):(2*N) ] = SIGMA_mu;
  for (i in 1:M){
    ind_st_sd[i] = sqrt(ind_st_var[i]);
    SIGMA_x[i] = diag_post_multiply(diag_pre_multiply(ind_st_sd[i],ind_st_cor[i]),ind_st_sd[i]);
	  SIGMA[((i+1) * N + 1):((i+2)*N ),((i + 1) * N + 1):((i+2)*N )] = SIGMA_x[i];
  }

  //SIGMA_init
  SIGMA_init[1:N,1:N] = diag_matrix(y_init_var);
  SIGMA_init[(N + 1):(2*N), (N + 1):(2*N) ] = SIGMA_mu ./ (1 - sha_st_ar_param * sha_st_ar_param');;
  for (i in 1:M){
    SIGMA_init[((i+1) * N + 1):((i+2)*N ),((i+1) * N + 1):((i+2)*N )] = SIGMA_x[i] ./ (1 - ind_st_ar_param[i] * ind_st_ar_param[i]');

  }

  //JM 28/02/22: Now do this earlier.
  //ind_lt_sd = sqrt(ind_lt_var);
  //ind_lt_covar = diag_post_multiply(diag_pre_multiply(ind_lt_sd,ind_lt_cor),ind_lt_sd);
  //ind_lt_cov_cholesky = cholesky_decompose(ind_lt_covar);
  lt_discrepancies[1:(2 * N)] = append_row(rep_vector(0.0,N), sha_lt);
  AR_params[1:(2 * N)] = append_row(rep_vector(1.0,N), sha_st_ar_param);
  for (i in 1:M){
    ind_lt[i] = ind_lt_cov_cholesky*ind_lt_raw[i];
    lt_discrepancies[((i+1) * N + 1):((i+2)*N )] = ind_lt[i];
	  AR_params[((i+1) * N + 1):((i+2)*N )] = ind_st_ar_param[i];
  }
}
model{
  /**
  * Priors
  */
  y_init_mean ~ normal(0, prior_y_init_mean_sd);    // Initial value of y
  y_init_var  ~ inv_gamma(prior_y_init_var_a, prior_y_init_var_b); // Initial variance of y
  SIGMA_t ~ inv_wishart(prior_sigma_t_inv_wish_nu, prior_sigma_t_inv_wish_sigma); // the random walk of y


  // Shared discrepancies
  sha_lt_raw ~ std_normal();
  //sha_st_var ~ exponential(prior_sha_st_var_exp); // Variance
  sha_st_var ~ inv_gamma(prior_sha_st_var_a,prior_sha_st_var_b); // Variance
  // Correlation matrix
  if(form_prior_sha_st == 0){
    sha_st_cor ~ lkj_corr(prior_sha_st_cor_lkj[1]);
  } else if(form_prior_sha_st == 1){
    sha_st_cor ~ inv_wishart(prior_sha_st_cor_wish_nu[1], prior_sha_st_cor_wish_sigma);
  } else {
    target += priors_cor_beta(sha_st_cor, N, prior_sha_st_cor_beta_1, prior_sha_st_cor_beta_2);
  }


  // Individual discrepancies
  // Note that we're assuming long-term discrepancies are drawn from a N(0,C) distribution
  // where C is independent of the model. This means we treat C outside the for loop.
  ind_lt_var ~ inv_gamma(prior_ind_lt_var_a,prior_ind_lt_var_b); // Variance
  //Long term correlations
  if(form_prior_ind_lt == 0){
    ind_lt_cor ~ lkj_corr(prior_ind_lt_cor_lkj[1]);
  } else if(form_prior_ind_lt == 1){
    ind_lt_cor ~ inv_wishart(prior_ind_lt_cor_wish_nu[1], prior_ind_lt_cor_wish_sigma);
  } else {
    target += priors_cor_beta(ind_lt_cor, N, prior_ind_lt_cor_beta_1, prior_ind_lt_cor_beta_2);
  }
  for(i in 1:M){
    ind_lt_raw[i] ~ std_normal();
    ind_st_var[i] ~ inv_gamma(prior_ind_st_var_a, prior_ind_st_var_b);// Variance

    // Correlation matrix
    if(form_prior_ind_st == 0){
      ind_st_cor[i] ~ lkj_corr(prior_ind_st_cor_lkj[1]);
    } else if(form_prior_ind_st == 1){
      ind_st_cor[i] ~ inv_wishart(prior_ind_st_cor_wish_nu[1], prior_ind_st_cor_wish_sigma);
    } else {
      target += priors_cor_beta(ind_st_cor[i], N, prior_ind_st_cor_beta_1, prior_ind_st_cor_beta_2);
    }
  }

  /**
   * Likelihood
   */
  // Kalman filter
  //target += KalmanFilter_seq_em(AR_params, lt_discrepancies, all_eigenvalues_cov, SIGMA, bigM,
  //                              SIGMA_init, x_hat, time, new_data, observation_available);
}
