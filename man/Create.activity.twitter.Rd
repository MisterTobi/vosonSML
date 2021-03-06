% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Create.activity.twitter.R
\name{Create.activity.twitter}
\alias{Create.activity.twitter}
\title{Create twitter activity network}
\usage{
\method{Create}{activity.twitter}(datasource, type, verbose = TRUE, ...)
}
\arguments{
\item{datasource}{Collected social media data with \code{"datasource"} and \code{"twitter"} class names.}

\item{type}{Character string. Type of network to be created, set to \code{"activity"}.}

\item{verbose}{Logical. Output additional information about the network creation. Default is \code{TRUE}.}

\item{...}{Additional parameters passed to function. Not used in this method.}
}
\value{
Network as a named list of two dataframes containing \code{$nodes} and \code{$edges}.
}
\description{
Creates a twitter activity network from collected tweets. Nodes are tweets and directed edges represent
the relationship of tweets to one another. For example, there is a directed edge from a quote tweet towards the
tweet that was quoted. Stand-alone tweets that are not replies, retweets or quote tweets have no relation to others
and will be isolates.
}
\examples{
\dontrun{
# create a twitter activity network graph
activityNetwork <- twitterData \%>\% Create("activity")
  
# network
# activityNetwork$nodes
# activityNetwork$edges
}

}
