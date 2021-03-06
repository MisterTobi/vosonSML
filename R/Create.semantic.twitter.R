#' @title Create twitter semantic network
#' 
#' @description Creates a semantic network from tweets returned from the twitter search query. Semantic networks 
#' describe the semantic relationships between concepts. In this network the concepts are significant words and terms 
#' (hashtags) extracted from the text corpus of the tweet data, and actors represented as nodes. Network edges are 
#' weighted and represent usage of frequently occurring terms and hashtags by the actors.
#'
#' @param datasource Collected social media data with \code{"datasource"} and \code{"twitter"} class names.
#' @param type Character string. Type of network to be created, set to \code{"semantic"}.
#' @param removeTermsOrHashtags Character vector. Terms or hashtags to remove from the semantic network. For example, 
#' this parameter could be used to remove the search term or hashtag that was used to collect the data by removing any
#' nodes with matching name. Default is \code{NULL} to remove none.
#' @param stopwordsEnglish Logical. Removes English stopwords from the tweet data. Default is \code{TRUE}.
#' @param termFreq Numeric integer. Specifies the percentage of most frequent terms to include. For example, a 
#' \code{termFreq = 20} means that the 20 percent most frequently occurring \code{terms} will be included in the 
#' semantic network as nodes. A larger percentage will increase the number of nodes and therefore the size of graph. 
#' The default value is \code{5}, meaning the top 5 percent most frequent terms are used.
#' @param hashtagFreq Numeric integer. Specifies the percentage of most frequent \code{hashtags} to include. For 
#' example, a \code{hashtagFreq = 80} means that the 80 percent most frequently occurring hashtags will be included 
#' in the semantic network as nodes. The default value is \code{50}.
#' @param verbose Logical. Output additional information about the network creation. Default is \code{FALSE}.
#' @param ... Additional parameters passed to function. Not used in this method.
#' 
#' @return Network as a named list of two dataframes containing \code{$nodes} and \code{$edges}.
#' 
#' @examples
#' \dontrun{
#' # create a twitter semantic network graph removing the hashtag '#auspol' and using the
#' # top 2% frequently occurring terms and 10% frequently occurring hashtags as additional 
#' # concepts or nodes
#' semanticNetwork <- twitterData %>% 
#'                    Create("semantic", removeTermsOrHashtags = c("#auspol"), termFreq = 2,
#'                           hashtagFreq = 10, verbose = TRUE)
#' 
#' # network
#' # semanticNetwork$nodes
#' # semanticNetwork$edges
#' }
#' 
#' @export
Create.semantic.twitter <- function(datasource, type, removeTermsOrHashtags = NULL, stopwordsEnglish = TRUE, 
                                    termFreq = 5, hashtagFreq = 50, verbose = FALSE, ...) {

  cat("Generating twitter semantic network...")
  if (verbose) { cat("\n") }
  
  # default to the top 5% most frequent terms. reduces size of graph
  # default to the top 50% hashtags. reduces size of graph. hashtags are 50% because they are much less 
  # frequent than terms.

  if (!is.null(removeTermsOrHashtags) && length(removeTermsOrHashtags)) {
    removeTermsOrHashtags <- as.vector(removeTermsOrHashtags) # coerce to vector
    removeTermsOrHashtags <- unlist(lapply(removeTermsOrHashtags, tolower))
  }
  
  df <- datasource # match the variable names (this must be used to avoid warnings in package compilation)
  # df <- tibble::as_tibble(datasource)
  
  # if df is a list of dataframes, then need to convert these into one dataframe
  suppressWarnings(
    if (class(df) == "list") {
      df <- do.call("rbind", df)
    })
  
  # now create the dfSemanticNetwork3, a dataframe of relations between hashtags and terms (i.e. hashtag i and term j 
  # both occurred in same tweet (weight = n occurrences))
  
  df_stats <- networkStats(NULL, "collected tweets", nrow(df))
  
  # added hash to hashtags to identify and merge them in results
  df$hashtags <- lapply(df$hashtags, function(x) ifelse(is.na(x), NA, paste0("#", x)))
  
  # convert the hashtags to lowercase here (before using tm_map later) but first deal with character encoding
  # if (isMac()) {
  #   df$hashtags <- lapply(df$hashtags, function(x) TrimOddCharMac(x))
  #   # df$text <- iconv(df$text, to = "utf-8-mac")
  # } else {
  #   df$hashtags <- lapply(df$hashtags, function(x) TrimOddChar(x))
  #   # df$text <- iconv(df$text, to = "utf-8")
  # }
  
  df$text <- HTMLdecode(df$text)
  
  # and then convert to lowercase
  df$text <- tolower(df$text)
  df$hashtags <- lapply(df$hashtags, tolower)
  
  # test - remove terms at this point?
  
  # macMatch <- grep("darwin", R.Version()$os)
  # if (length(macMatch) != 0) {
  #   # df$hashtags_used <- iconv(df$hashtags_used, to = "utf-8-mac")
  #   df$hashtags <- lapply(df$hashtags, function(x) TrimOddCharMac(x))
  # }
  # 
  # if (length(macMatch) == 0) {
  #   df$hashtags <- lapply(df$hashtags, function(x) TrimOddChar(x))
  # }
  
  # and then convert to lowercase
  # df$hashtags <- lapply(df$hashtags, tolower)
  
  # do the same for the comment text, but first deal with character encoding!
  # we need to change value of `to` argument in 'iconv' depending on OS, or else errors can occur
  # macMatch <- grep("darwin", R.Version()$os)
  # if (length(macMatch) != 0) {
  #   df$text <- iconv(df$text, to = "utf-8-mac")
  # }
  # 
  # if (length(macMatch) == 0) {
  #   df$text <- iconv(df$text, to = "utf-8")
  # }

  hashtagsUsedTemp <- c() # temp var to store output
  
  # the 'hashtags_used' column in the 'df' dataframe is slightly problematic (i.e. not straightforward)
  # because each cell in this column contains a LIST, itself containing 1 or more char vectors (which are unique 
  # hashtags found in the tweet text; empty if no hashtags used).
  # so, need to extract each list item out, and put it into its own row in a new dataframe
  count <- 0
  for (i in 1:nrow(df)) {
    if (!is.na(df$hashtags[[i]]) && length(df$hashtags[[i]]) > 0) { # skip any rows where NO HASHTAGS were used
      for (j in 1:length(df$hashtags[[i]])) {
        count <- count + 1
        #commonTermsTemp <- c(commonTermsTemp, df$from_user[i])
        if (!is.na(df$hashtags[[i]][j])) {
          hashtagsUsedTemp <- c(hashtagsUsedTemp, df$hashtags[[i]][j]) 
        }
      }
    }
  } # try and vectorise this in future work to improve speed
  df_stats <- networkStats(df_stats, "raw hashtags", count, FALSE)
  
  hashtagsUsedTemp <- unique(hashtagsUsedTemp)
  unique_hashtags <- hashtagsUsedTemp
  df_stats <- networkStats(df_stats, "unique hashtags", length(hashtagsUsedTemp), FALSE)
  
  hashtagsUsedTempFrequency <- c()
  
  # potentially do not want EVERY hashtag - just the top N% (most common)
  for (i in 1: length(hashtagsUsedTemp)) {
    hashtagsUsedTempFrequency[i] <- length(grep(hashtagsUsedTemp[i], df$text))
  }
  
  mTemp <- cbind(hashtagsUsedTemp, hashtagsUsedTempFrequency)
  mTemp2 <- as.matrix(as.numeric(mTemp[, 2]))
  names(mTemp2) <- mTemp[, 1]
  vTemp <- sort(mTemp2, decreasing = TRUE)
  
  # this defaults to top 50% hashtags
  hashtagsUsedTemp <- names(head(vTemp, (length(vTemp) / 100) * hashtagFreq))
  df_stats <- networkStats(df_stats, paste0("top ", hashtagFreq , "% hashtags"), length(hashtagsUsedTemp), FALSE)
  
  # we need to remove all punctuation EXCEPT HASHES (!) (e.g. both #auspol and auspol will appear in data)
  
  # this is a decision point for non-english text
  # df$text <- gsub("[^[:alnum:][:space:]#]", "", df$text)
  
  # remove twitter shortened urls so dont get weird strings after punctuation removal
  df$text <- gsub("https://t.co/[a-zA-Z0-9]+\\s", "", df$text, ignore.case = TRUE, perl = TRUE)
  
  # remove punctuation except # and @
  df$text <- gsub("([#@])|[[:punct:]]", "\\1", df$text)
  
  # find the most frequent terms across the tweet text corpus
  commonTermsTemp <- df$text
  
  corpusTweetText <- Corpus(VectorSource(commonTermsTemp))
  
  # add usernames to stopwords
  # mach_usernames <- sapply(df$screen_name, function(x) TrimOddChar(x))
  mach_usernames <- unique(df$screen_name)
  
  # if (isMac()) {
  #   mach_usernames <- iconv(mach_usernames, to = "utf-8-mac")
  # } else {
  #   mach_usernames <- iconv(mach_usernames, to = "utf-8")
  # }

  # we remove the usernames from the text (so they don't appear in data/network)
  my_stopwords <- mach_usernames
  corpusTweetText <- suppressWarnings(tm_map(corpusTweetText, removeWords, my_stopwords))
  
  # remove terms
  # if (removeTermsOrHashtags[1] != "foobar") {
  #   corpusTweetText <- suppressWarnings(tm_map(corpusTweetText, removeWords, removeTermsOrHashtags))
  # }
  
  # convert to all lowercase (WE WILL DO THIS AGAIN BELOW, SO REMOVE THIS DUPLICATE)
  # corpusTweetText <- tm_map(corpusTweetText, content_transformer(tolower))
  
  # remove English stop words (IF THE USER HAS SPECIFIED!)
  if (stopwordsEnglish) {
    corpusTweetText <- suppressWarnings(tm_map(corpusTweetText, removeWords, stopwords("english")))
  }
  
  # eliminate extra whitespace
  corpusTweetText <- suppressWarnings(tm_map(corpusTweetText, stripWhitespace))
  
  # create document term matrix applying some transformations
  # ** applying too many transformations here (duplicating...) - need to fix
  tdm = TermDocumentMatrix(corpusTweetText, control = list(removeNumbers = TRUE, tolower = TRUE))
  
  # create a vector of the common terms, finding the top N% terms
  # N will need to be adjusted according to network / user requirements
  mTemp <- as.matrix(tdm)
  vTemp <- sort(rowSums(mTemp), decreasing = TRUE)
  df_stats <- networkStats(df_stats, paste0("common terms"), length(vTemp), FALSE)
  
  ## the default finds top 5% terms
  commonTerms <- names(head(vTemp, (length(vTemp) / 100) * termFreq))
  
  # toDel <- grep("http", commonTerms) # !! still picking up junk terms (FIX)
  # if (length(toDel) > 0) {
  #   commonTerms <- commonTerms[-toDel] # delete these junk terms
  # }
  df_stats <- networkStats(df_stats, paste0("top ", termFreq , "% terms"), length(commonTerms), FALSE)
  
  # create the "semantic hashtag-term network" dataframe (i.e. pairs of hashtags / terms)
  
  termAssociatedWithHashtag <- c() # temp var to store output
  hashtagAssociatedWithTerm <- c() # temp var to store output
  
  for (i in 1:nrow(df)) {
    if (!is.na(df$hashtags[[i]]) && length(df$hashtags[[i]]) > 0) { # skip any rows where NO HASHTAGS were used
      for (j in 1:length(df$hashtags[[i]])) {
        for (k in 1:length(commonTerms)) {
          
          match <- grep(commonTerms[k], df$text[i])
          
          if (length(match) > 0) {
            termAssociatedWithHashtag <- c(termAssociatedWithHashtag, commonTerms[k])
            hashtagAssociatedWithTerm <- c(hashtagAssociatedWithTerm, df$hashtags[[i]][j])
          }
        }
      }
    }
  } # THIS IS A *HORRIBLE* LOOPED APPROACH. NEED TO VECTORISE!!!
  
  # this needs to be changed to termAssociatedWithHashtag and hashtagAssociatedWithTerm
  dfSemanticNetwork3 <- data.frame(hashtagAssociatedWithTerm, termAssociatedWithHashtag)
  
  # OK, now extract only the UNIQUE pairs (i.e. rows)
  # But, also create a WEIGHT value for usages of the same hashtag.
  # NOTE: This edge weights approach might be problematic for TEMPORAL networks, because each edge (with weight > 1) 
  # may represent usage of hashtags at DIFFERENT TIMES.
  # NOTE: A possible workaround could be to include an edge attribute that is a set of timestamp elements, showing the 
  # date/time of each instance of usage of a hashtag.
  # NOTE: For example, in a temporal visualisation, the first timestamp might 'pop in' the edge to the graph, which 
  # then might start to 'fade out' over time (or just 'pop out' of graph after N seconds) if there are no more 
  # timestamps indicating activity (i.e. a user using a hashtag).
  # NOTE: So, a 'timestamps' edge attribute could factor into a kind of 'entropy' based approach to evolving the 
  # network visually over time.
  
  # unique pairs
  unique_dfSemanticNetwork3 <- unique(dfSemanticNetwork3) # hmm, need this still?
  
  # number of times hashtag was used per user/hashtag pair (i.e. edge weight):
  for (i in 1:nrow(unique_dfSemanticNetwork3)) {
    unique_dfSemanticNetwork3$numHashtagTermOccurrences[i] <- sum(
      hashtagAssociatedWithTerm == unique_dfSemanticNetwork3[i, 1] & 
        termAssociatedWithHashtag == unique_dfSemanticNetwork3[i, 2]) # na.rm = TRUE
  }
  
  # make a dataframe of the relations between actors
  relations <- data.frame(from = as.character(unique_dfSemanticNetwork3[, 1]), 
                          to = as.character(unique_dfSemanticNetwork3[,2]),
                          weight = unique_dfSemanticNetwork3$numHashtagTermOccurrences)
  
  relations$from <- as.factor(relations$from)
  relations$to <- as.factor(relations$to)
  
  actorsFixed <- rbind(as.character(unique_dfSemanticNetwork3[, 1]), as.character(unique_dfSemanticNetwork3[, 2]))
  actorsFixed <- unique(as.factor(actorsFixed))

  df_stats <- networkStats(df_stats, "unique entities (nodes)", length(actorsFixed))
  df_stats <- networkStats(df_stats, "relations (edges)", nrow(relations))
  
  relations <- tibble::as_tibble(relations)
  actorsFixed <- tibble::as_tibble(actorsFixed)
  
  # remove the search term / hashtags, if user specified it
  if (length(removeTermsOrHashtags)) {
    # this should take place before freq % calculations
    relations %<>% dplyr::filter((!.data$to %in% removeTermsOrHashtags) &
                                 (!.data$from %in% removeTermsOrHashtags))
    actorsFixed %<>% dplyr::filter(!.data$value %in% removeTermsOrHashtags)
    
    df_stats <- networkStats(df_stats, "entities after terms/hashtags removed", nrow(actorsFixed))
    
    # # we force to lowercase because all terms/hashtags are already converted to lowercase
    # toDel <- match(tolower(removeTermsOrHashtags), V(g)$name)
    # 
    # # in case of user error (i.e. trying to delete terms/hashtags that don't exist in the data)
    # toDel <- toDel[!is.na(toDel)]
    # g <- delete.vertices(g, toDel)
    # df_stats <- networkStats(df_stats, "entities after terms/hashtags removed", vcount(g))
  }
  
  # print stats
  if (verbose) { networkStats(df_stats, print = TRUE) }
  
  func_output <- list(
    "nodes" = actorsFixed,
    "edges" = relations
  )
  
  class(func_output) <- union(class(func_output), c("network", "semantic", "twitter"))
  cat("Done.\n")
  
  func_output
}
