% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ImportData.R
\name{vosonSML::ImportData}
\alias{vosonSML::ImportData}
\alias{ImportData}
\title{Import collected data previously saved to file}
\usage{
ImportData(path, socialmedia, type = NULL)
}
\arguments{
\item{path}{Character string. Collected data file path.}

\item{socialmedia}{Character string. Social media type of collected data \code{twitter}, \code{youtube} or 
\code{reddit}.}

\item{type}{Character string. Type of file or file format of file to import \code{csv} or \code{rds}. Default is 
\code{NULL} to use extension.}
}
\value{
A dataframe with datasource class attributes.
}
\description{
Imports collected data from file into a dataframe of class \code{datasource} and specified 
\code{socialmedia} type that is usable by \code{\link{Create}} functions.
}
