---
layout: post
title: Rcpp - Using C++ and R code Together 
categories: [tutorial]
tags: [Rcpp, RcppArmadillo, OpenMP]
---
This tutorial was presented as part of PH 1930 Statistical Computing. The examples for this session are available on Github at the <a href="https://github.com/kan-li/Rcpp-arms" target="_blank">link</a>.

[Overview](#OV)<br>
[Configure the environment](#CE)<br>
[Rcpp and RcppArmadillo](#Rcpp)<br>
[Getting started](#Start)<br>
[First example](#FE)<br>
[Parallelization](#OpenMP)<br>
[MCMC for GLMM](#MCMC)<br>


While it is possible to write C or Fortran code for use in R as covered previously in this course, Rcpp provides a clean, approachable API that lets we write high-performance code much easily and joyfully.


<span id="OV">
##Overview
</span>

In general, R is not a fast or most memory efficient language -- but it is very easy to use, to share, and makes very pretty output. C++ is very fast, but not so easy to use, and debugging could be painful. Rcpp supports implementing R functions in C++ for high performance computing and to easily interface R with external libraries.

<span id="CE">
##Configure the environment for using C++ code with R
</span>

I only test the tool on Windows and Linux. No matter which platform you prefer, <a href="https://www.rstudio.com/" target="_blank">RStudio</a> is highly recommended to do the work. For a Windows user, you will need to make sure you have the latest release of R (3.2.0+) and will also need to install the <a href="http://cran.r-project.org/bin/windows/Rtools">Rtools</a>  library before you can use any packages with C++ code in them. Usually RStudio will help to check whether the Rtools are installed and install it for you when you first use Rcpp. If you are Linux user, everything probably just works. You may also want to visit this <a href="https://cdrv.wordpress.com/2013/01/12/getting-compilers-to-work-with-rcpp-rcpparmadillo/">blog post</a> which has more information on making C++ work with R under Windows/Mac if you end up encountering any weirdness. 

<span id="Rcpp">
##Rcpp and RcppArmadillo
</span>

In this session we’ll learn how to improve our R code performance by rewriting key functions in C++. Typical bottlenecks that C++ can address include:

- Loops that can’t be easily vectorized because subsequent iterations depend on previous ones.
- Recursive functions, or problems which involve calling functions millions of times. The overhead of calling a function in C++ is much lower than that in R.
- Problems that require advanced data structures and algorithms that R doesn’t provide. Through the standard template library (STL), C++ has efficient implementations of many important data structures, from ordered maps to double-ended queues.

To use Rcpp, a working knowledge of C++ is helpful, but not essential. Many good tutorials and references are freely available, including  <a href="http://www.learncpp.com/">http://www.learncpp.com/</a>  and <a href="http://www.cplusplus.com/">http://www.cplusplus.com/</a>.  You may also enjoy Dirk Eddelbuettel’s <a href="http://www.springer.com/statistics/computational+statistics/book/978-1-4614-6867-7">Seamless R and C++ integration with Rcpp</a>, which goes into much detail into all aspects of Rcpp.

<code>RcppArmadillo</code> is an add-on package that gives you access to tons of useful linear algebra functionality in C++. In particular it makes passing in and working with arrays, matrices and vectors pretty easy. You can check out the Armadillo docs here: <a href="http://arma.sourceforge.net/docs.html">http://arma.sourceforge.net/docs.html</a>. This is where I go to look up functions to see how to use them or if they exist.

Although the base Rcpp package provides its own data structures (e.g., array, matrix, list) that can be passed easily between R and C++, the Armadillo data structures provided by the <code>RcppArmadillo</code>  package are really nice and easier to use. Additionally, the Armadillo data structures are native C++ data structures, have multi-thread support and less unpredictable bad errors are encountered in practice. So I suggest using Armadillo data structures in most cases.

<span id="Start">
##Getting started
</span>

Before we start the first example, we install the two R package using 
<pre><code class="language-r">
install.packages("Rcpp")
install.packages("RcppArmadillo")
</code></pre>
in Rstudio command line.

We start by creating a new file in RStudio by clicking on the icon in the top left corner of the screen and select <strong>C++ File</strong> from the drop down menu.
<img src="{{ site.url }}/image/post/Rcpp/create_file.png" id="mainImg0" class="mainImgStyle"> <br> 

A sample <em>timesTwo</em>* C++ program will pop up. We will now need to save that file somewhere. Once we have done so, we can click on the <strong>Source</strong> button and you will see that RStudio automatically calls <code>Rcpp::sourceCpp()</code> on the file.  
<img src="{{ site.url }}/image/post/Rcpp/check_run.png" id="mainImg1" class="mainImgStyle"> <br> 

This will compile the function and make it so we can access the C++ code from R -  much easier than Calling C from R we taught before. The example can help you to check everything needed are correctly installed on your computer.

**Some other things to note**:

- This statement include Rcpp header file in the program. The function is similar as <code>library( )</code> in R.  It also tells us that we can call any Rcpp constructs by their given name without the <code>Rcpp::</code> prefix.
<pre><code class="language-cpp">
#include &lt;Rcpp.h&gt;
using namespace Rcpp;
</code></pre>

- We also put this statement before each function we want to make available to R:
<pre><code class="language-cpp">
//[[Rcpp::export]]
</code></pre>

We can also define multiple C++ functions in the same file (not necessarily recommended unless some of them will be used by the main function), so we can put one in front of each one we want to make visible.

-  We can include R code blocks in C++ files processed with <code> sourceCpp </code>. The R code will be automatically run after the compilation.
<pre><code class="language-cpp">
/*** R
timesTwo(42)
*/
</code></pre>

<span id="FE">
##First example
</span>
We introduce our first example of calculating inner product of two vectors, and use data structure of Armadillo. The C++ code is:
<pre><code class="language-cpp">
#include &lt;RcppArmadillo.h&gt;
// [[Rcpp::depends( RcppArmadillo)]]
using namespace arma;

// [[Rcpp::export]]
arma::mat inner(arma::vec x, arma::vec y){
  arma::mat ip=x.t()*y;
  return(ip);
}

/*** R
vecA = rnorm(100000)
*/
</code></pre>

Note that we no longer use the:
<pre><code class="language-cpp">#include &lt;Rcpp.h&gt;
</code></pre>
statement as in the example code provided by RStudio, but replace it with:
<pre><code class="language-cpp">
#include &lt;RcppArmadillo.h&gt;
//[[Rcpp::depends(RcppArmadillo)]]
</code></pre>

Also note that for all of the objects, we have to specify their type as we define the argument. This is a feature of C++ that is different from R where we just create objects without having to specify their type. Some basic C++ Armadillo objects we can pass in:

- For <strong>decimal numbers</strong> like <code>1.2347</code> we need to use the <code>double</code> declaration, followed by the name of the argument (e.g.. <code>my_double</code>)
- For <strong>integers</strong> (whole numbers) like <code>26</code> we use the <code>int</code> declaration, followed by the argument. 
- For <strong>numeric vectors</strong>, we use the <code>arma::vec</code> declaration, followed by the argument. This code should crash if you try to pass in anything other than a numeric vector  (can contain doubles or integers). When you refer to the *i* th elements of a vector such as <code> x </code>, we use  <code> x(i) </code> instead of <code> x[i] </code> as in R.
- For <strong>numeric matrices</strong>, we use the <code>arma::mat</code> declaration, followed by the argument. Again, make sure it is just numbers in there.  

We then write following R code and run it.

<pre><code class="language-r">
> library(Rcpp)
> library(RcppArmadillo)

> sourceCpp('test.cpp')
> vecA = rnorm(100000)

> inner(vecA,vecA)
         [,1]
[1,] 100317.2
</code></pre>


<span id="OpenMP">
##Parallelization in Rcpp via OpenMP
</span>

Now we make a small extension of the example and simply introduce using OpenMP to parallelize our C++ function. In order for the compiler to recognize OpenMP, we need to include the OpenMP header flag.  Additionally, Rcpp has a plugin that will automatically add the OpenMP compiler flags.  Add the following to the top of your C++ program.

<pre><code class="language-cpp">
#include &lt;omp.h&gt;
// [[Rcpp::plugins(openmp)]]
</code></pre>

We also have to set some compiler flags in R code. Add the following to your R code.

<pre><code class="language-cpp">
Sys.setenv("PKG_CXXFLAGS" = "-fopenmp")
Sys.setenv("PKG_LIBS" = "-fopenmp")
</code></pre>

The example we are going to use is element-wised sum square of a vector. It is a special case of the inner product of two same vectors.  In serial way, we can realize this in Rcpp like so:

<pre><code class="language-cpp">
// [[Rcpp::export]]
double sumsq_serial(vec x)
{
  double sum = 0.0;
  for (int i=0; i&lt;x.size(); i++){
    sum += sq(x(i));
  }  
  return sum;
}
</code></pre>

The function <code> sq()</code>  is simply squaring a number as
<pre><code class="language-cpp">
double sq(double x){
  return(x*x);
}
</code></pre>

I do not put <code> // [[Rcpp::export]] </code> before this function because I will never call it from R. Calling such a function will slow down the performance of the code, comparing with <code class="language-cpp"> sum += x(i)*x(i); </code>. I include a function here to ascertain that each thread can correctly recognizes the user defined function when doing parallel computing later.

And in parallel using OpenMP, we just add the basic compiler pragma:
<pre><code class="language-cpp">
// [[Rcpp::export]]
double sumsq_parallel(vec x, int ncores)
{
  double sum = 0.0;
  omp_set_num_threads(ncores);
  #pragma omp parallel for shared(x) reduction(+:sum)
  for (int i=0; i&lt;x.size(); i++){
	// cout &lt;&lt; i &lt;&lt; ", "omp_get_thread_num() &lt;&lt;  " of " &lt;&lt;  omp_get_num_threads() << endl;
    sum += sq(x(i));
  }
  return sum;
}
</code></pre>

Basically, we identify the loop in which we want to parallelize and add the following lines above it
<pre><code class="language-cpp">
omp_set_num_threads(int)
#pragma omp parallel for
</code></pre>

The first line selects the number of cores to use.  This should not exceed the number of cores in your system.  If we do not write this line, all the cores available on your computer will be used. The only real trick here in this example is making use of the <code> shared() </code> and <code> reduction() </code> keyword, and it pretty much does what it looks like. We’re telling the compiler that while each iteration of the loop should be run in parallel, they share the same information from vector <code> x </code>, and in the end we want the private (by thread) copies of the variable <code> sum </code> to be added up.  The code <code> cout &lt;&lt;  i &lt;&lt;  ", "omp_get_thread_num() &lt;&lt;  " of " &lt;&lt;  omp_get_num_threads() &lt;&lt;  endl; </code> is C++ standard way to do <code> print() </code>. This code just tells which thread is currently working on the *i* th iteration, and the total number of thread are working together.

A small experiment is used to compare different methods proposed. A small set of micro-benchmarks in a variety of methods are conducted.
<pre><code class="language-r">
library(rbenchmark)
bench = benchmark(
		  vecA%*%vecA,
          inner(vecA,vecA),
          sumsq_parallel(vecA,1),
          sumsq_parallel(vecA,2),
          sumsq_parallel(vecA,3),
          sumsq_parallel(vecA,4), order = NULL, replications=1000)

print(bench[,1:4])

# test replications elapsed relative
# 1           vecA %*% vecA         1000   0.721    4.682
# 2       inner(vecA, vecA)         1000   0.229    1.487
# 3 sumsq_parallel(vecA, 1)         1000   0.319    2.071
# 4 sumsq_parallel(vecA, 2)         1000   0.203    1.318
# 5 sumsq_parallel(vecA, 3)         1000   0.154    1.000
# 6 sumsq_parallel(vecA, 4)         1000   0.157    1.019
</code></pre>

We can see that C++ functions are much faster than R function <code> %*% </code>. As more cores were used in parallel computing, the execution time becomes shorter. Because I only had 4 cores on my desktop, the maximal number of core I tested was 4. It seems requiring all the resources on your computer to do the work may slow down the overall performance. 

<span id="MCMC">
##MCMC for GLMM
</span>

This tutorial session has only touched on a small part of Rcpp, giving you the basic tools to rewrite poorly performing R code in C++. With the basic knowledge of Rcpp, it will be much easier for you to understand the example of MCMC for generalized linear mixed model using Adaptive rejection Metropolis sampling (ARMS) I provide <a href="https://github.com/kan-li/Rcpp-arms" target="_blank">here</a> . Three methods are compared. The first method is pure R code, using the <code> arms </code> function in R <code> Hi </code> package. The second method is writing log density functions in C++, but sampling process is still coded in R with modified <code> arms </code> function.  The third method is coding both log density functions and sampling process in Rcpp/C++. The pure R example takes 36.14 mins. The hybrid method takes 9.80 mins and the C++ code used only 1.17 mins. 

The log density function coded in R:
<pre><code class="language-r">
logden.beta &lt; - function(x, myu) {
  myu.long &lt; - as.vector(mapply(rep, myu, nobs))
  temp &lt; - as.vector(design.matrix %*% as.matrix(x, ncol=1)) + myu.long
  return(sum(y*temp - log(1+exp(temp))))
}

logden.u &lt; - function(x, mybeta, myy, mycovariate, mytau) {
  temp &lt;- mycovariate %*% as.matrix(mybeta, ncol=1) + x
  return(sum(myy * temp - log(1+exp(temp))) - 0.5*x^2*mytau)
}
</code></pre>

The log density function coded in C++:

<pre><code class="language-cpp">
// [[Rcpp::export]]
double logden_beta(vec x, vec myu_long, mat design_matrix, vec y){
  vec temp = design_matrix*x + myu_long;
  vec one; one.ones(size(temp));
  vec logden = y%temp - log(one + exp(temp));
  return(sum(logden));
}

// [[Rcpp::export]]
double logden_u(double x, vec mybeta, vec myy, mat mycovariate, double mytau){
  vec x_long(size(myy)); x_long.fill(x);
  vec temp = mycovariate*mybeta + x_long;
  vec one; one.ones(size(temp));
  vec logden = myy%temp - log(one + exp(temp));
  return(sum(logden)-0.5*pow(x,2)*mytau);
}
</code></pre>

<span id="MCMC">
##Common Pitfalls
</span>

- The number one pitfall I have made while working with C++ and R is forgetting that while R starts vector and matrix indexes from 1, C++ (along with pretty much every other programming language), starts indexes from zero, so you need to plan accordingly.
- In C++, we need to define the variable before use it while R does not require that.
- Don't forget to write the semicolon after each line of the code in C++.

<span id="MCMC">
## Resources
</span>

For additional information and advanced use, following resources provide a helpful introduction:

- [Rcpp: Seamless R and C++ Integration](http://www.springer.com/statistics/computational+statistics/book/978-1-4614-6867-7)
- [Rcpp website](http://www.rcpp.org/)
- [Rcpp book](http://www.rcpp.org/book/)
- [Rcpp Quick Reference Guide](http://cran.rstudio.com/web/packages/Rcpp/vignettes/Rcpp-quickref.pdf)
- [High performance functions with Rcpp](http://adv-r.had.co.nz/Rcpp.html)
- [Introduction to Rcpp Attributes](http://cran.rstudio.com/web/packages/Rcpp/vignettes/Rcpp-attributes.pdf)
- [Gallery of examples](http://gallery.rcpp.org/)
- [Armadillo C++ linear algebra library](http://arma.sourceforge.net/docs.html)
- [Guide into OpenMP](http://bisqwit.iki.fi/story/howto/openmp/)
- [Introduction to MPI and OpenMP](http://www.ee.ryerson.ca/~courses/ee8218/mpi_openmp.pdf)

<head>
	<link href="{{ site.url }}/media/css/prism.css" rel="stylesheet" />
</head>
<body>
	<script src="{{ site.url }}/media/js/prism.js"></script>
</body>
