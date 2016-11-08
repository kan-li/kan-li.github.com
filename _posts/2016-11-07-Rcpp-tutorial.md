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
[First Example](#FE)<br>

While it is possible to write C or Fortran code for use in R as covered previously in this course, Rcpp provides a clean, approachable API that lets we write high-performance code much easily and joyfully.


<span id="OV">
##Overview
</span>

In general, R is not a fast or most memory efficient language -- but it is very easy to use, to share, and makes very pretty output. C++ is very fast, but not so easy to use, and debugging could be painful. Rcpp supports implementing R functions in C++ for high performance computing and to easily interface R with external libraries.
Configure the environment for using C++ code with R

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
</code>
</pre>
in Rstudio command line.

We start by creating a new file in RStudio by clicking on the icon in the top left corner of the screen and select <strong>C++ File</strong> from the drop down menu.
<img src="{{ site.url }}/image/post/Rcpp/create_file.png" id="mainImg0" class="mainImgStyle"> <br> 

A sample <em>timesTwo</em>* C++ program will pop up. We will now need to save that file somewhere. Once we have done so, we can click on the <strong>Source</strong> button and you will see that RStudio automatically calls <code>Rcpp::sourceCpp()</code> on the file.  
<img src="{{ site.url }}/image/post/Rcpp/check_run.png" id="mainImg1" class="mainImgStyle"> <br> 

This will compile the function and make it so we can access the C++ code from R -  much easier than Calling C from R we taught before. The example can help you to check everything needed are correctly installed on your computer.

Some other things to note:
- This statement include Rcpp header file in the program. The function is similar as library( ) in R.  It also tells us that we can call any Rcpp constructs by their given name without the <code>Rcpp::</code> prefix.
<pre><code class="language-cpp">
#include <Rcpp.h>
using namespace Rcpp;
</code>
</pre>


- We also put one of these statements before each function we want to make available to R:

<pre><code class="language-cpp">
/[[Rcpp::export]]
</code>
</pre>

We can also define multiple C++ functions in the same file (not necessarily recommended unless some of them will be used by the main function), so we can put one in front of each one we want to make visible.

-  We can include R code blocks in C++ files processed with sourceCpp. The R code will be automatically run after the compilation.

<pre><code class="language-cpp">
/*** R
timesTwo(42)
*/
</code>
</pre>


<head>
	...
	<link href="{{ site.url }}/media/css/prism.css" rel="stylesheet" />
</head>
<body>
	...
	<script src="{{ site.url }}/media/js/prism.js"></script>
</body>
