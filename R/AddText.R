#' @title Add columns containing text data to network dataframes
#' 
#' @description Network is supplemented with additional social media text data applied as node or edge attributes.
#' 
#' @note Supports all \code{activity} and \code{actor} networks. Refer to \code{\link{AddText.activity.reddit}} and
#' \code{\link{AddText.actor.reddit}} for additional reddit parameters. Refer to \code{\link{AddText.actor.youtube}}
#' for additional youtube actor network parameters.
#' 
#' @param net A named list of dataframes \code{nodes} and \code{edges} generated by \code{Create}.
#' @param data A dataframe generated by \code{Collect}.
#' @param ... Additional parameters passed to function.
#' 
#' @return Network as a named list of two dataframes containing \code{$nodes} and \code{$edges}
#' including columns containing text data.
#' 
#' @examples
#' \dontrun{
#' # add text to an activity network
#' activityNetwork <- collectData %>% Create("activity") %>% AddText(collectData)
#' 
#' # network
#' # activityNetwork$nodes
#' # activityNetwork$edges
#' }
#' 
#' @aliases AddText
#' @name vosonSML::AddText
#' @export
AddText <- function(net, data, ...) {
  cat("Adding text to network...")
  
  # searches the class list of net for matching method
  UseMethod("AddText", net)
}

#' @noRd
#' @export
AddText.default <- function(net, data, ...) {
  stop("Unknown network type passed to AddText.", call. = FALSE) 
}

#' @noRd
#' @method AddText activity
#' @export
AddText.activity <- function(net, data, ...) {
  UseMethod("AddText.activity", net)
}

#' @noRd
#' @export
AddText.activity.default <- function(net, data, ...) {
  stop("Unknown social media type passed to AddText.", call. = FALSE)
}

#' @noRd
#' @export
AddText.activity.twitter <- function(net, data, ...) {
  net$nodes <- dplyr::left_join(net$nodes, dplyr::select(data, .data$status_id, .data$text), by = "status_id")
  net$nodes <- dplyr::left_join(net$nodes, 
                                dplyr::select(data, .data$quoted_status_id, .data$quoted_text) %>%
                                  dplyr::rename(status_id =.data$quoted_status_id, qtext = .data$quoted_text) %>%
                                  dplyr::distinct(), by = "status_id")
  net$nodes <- dplyr::left_join(net$nodes, 
                                dplyr::select(data, .data$retweet_status_id, .data$retweet_text) %>%
                                  dplyr::rename(status_id =.data$retweet_status_id, rtext = .data$retweet_text) %>%
                                  dplyr::distinct(), by = "status_id")
  net$nodes <- dplyr::mutate(net$nodes, text = ifelse(!is.na(.data$text), .data$text,
                                                      ifelse(!is.na(.data$qtext), .data$qtext, .data$rtext))) %>%
    dplyr::select(-c(.data$qtext, .data$rtext)) %>% dplyr::rename(vosonTxt_tweet = .data$text)
  
  net$nodes$vosonTxt_tweet <- HTMLdecode(net$nodes$vosonTxt_tweet)
  
  class(net) <- union(class(net), c("voson_text"))
  cat("Done.\n")
  
  net
}

#' @noRd
#' @export
AddText.activity.youtube <- function(net, data, ...) {
  net$nodes <- dplyr::left_join(net$nodes, 
                                dplyr::select(data, .data$CommentID, .data$Comment) %>%
                                  dplyr::rename(id = .data$CommentID, vosonTxt_comment = .data$Comment), 
                                by = c("id"))
  
  class(net) <- union(class(net), c("voson_text"))
  cat("Done.\n")
  
  net
}

#' @title Add columns containing text data to reddit activity network dataframes
#' 
#' @param net A named list of dataframes \code{nodes} and \code{edges} generated by \code{Create}.
#' @param data A dataframe generated by \code{Collect}.
#' @param cleanText Logical. Simple removal of problematic characters for XML 1.0 standard. Implemented to prevent
#' reddit specific XML control character errors when generating graphml files. Default is \code{TRUE}.
#' @param ... Additional parameters passed to function. Not used in this method.
#' 
#' @return Network as a named list of two dataframes containing \code{$nodes} and \code{$edges}
#' including columns containing text data.
#'
#' @aliases AddText.activity.reddit
#' @name vosonSML::AddText.activity.reddit
#' @export
AddText.activity.reddit <- function(net, data, cleanText = FALSE, ...) {
  net$nodes <- dplyr::left_join(net$nodes, 
                                dplyr::mutate(data, id = paste0(.data$thread_id, ".", .data$structure)) %>%
                                  dplyr::select(.data$id, .data$subreddit, .data$comment), 
                                by = c("id", "subreddit"))
  
  threads <- dplyr::select(data, .data$subreddit, .data$thread_id, .data$title, .data$post_text) %>%
    dplyr::distinct() %>% dplyr::mutate(id = paste0(.data$thread_id, ".0"), thread_id = NULL)
  
  net$nodes <- dplyr::left_join(net$nodes, threads, by = c("id", "subreddit")) %>%
    dplyr::mutate(comment = ifelse(.data$node_type == "thread", .data$post_text, .data$comment)) %>%
    dplyr::select(-c(.data$post_text)) %>% dplyr::rename(vosonTxt_comment = .data$comment)
  
  if (cleanText) {
    net$nodes$vosonTxt_comment <- CleanRedditText(net$nodes$vosonTxt_comment)
    net$nodes$title <- CleanRedditText(net$nodes$title)
  }  
  
  class(net) <- union(class(net), c("voson_text"))
  cat("Done.\n")
  
  net
}

#' @noRd
#' @method AddText actor
#' @export
AddText.actor <- function(net, ...) {

  UseMethod("AddText.actor", net)
}

#' @noRd
#' @export
AddText.actor.default <- function(net, ...) {
  stop("Unknown social media type passed to AddText.", call. = FALSE)
}

#' @noRd
#' @export
AddText.actor.twitter <- function(net, data, ...) {
  net$edges <- dplyr::left_join(net$edges,
                                dplyr::select(data, .data$status_id, .data$text),
                                by = c("status_id")) %>%
               dplyr::rename(vosonTxt_tweet = .data$text)
  
  net$edges$vosonTxt_tweet <- HTMLdecode(net$edges$vosonTxt_tweet)
  
  class(net) <- union(class(net), c("voson_text"))
  cat("Done.\n")
  
  net
}

#' @title Add columns containing text data to youtube actor network dataframes
#' 
#' @description Text comments are added to the network as edge attributes. References to actors
#' are detected at the beginning of comments and edges redirected to that actor instead if they
#' differ from the top-level comment author. 
#' 
#' @param net A named list of dataframes \code{nodes} and \code{edges} generated by \code{Create}.
#' @param data A dataframe generated by \code{Collect}.
#' @param replies_from_text Logical. If comment text for an edge begins with \code{screen_name} change the
#' edge to be directed to \code{screen_name} - if different from the top level comment author that the reply
#' comment was posted to. Default is \code{FALSE}.
#' @param at_replies_only Logical. Comment \code{screen_names} must begin with an '@' symbol to be redirected.
#' Default is \code{TRUE}.
#' @param ... Additional parameters passed to function. Not used in this method.
#' 
#' @return Network as a named list of two dataframes containing \code{$nodes} and \code{$edges}
#' including columns containing text data.
#'
#' @examples
#' \dontrun{
#' # add text to an actor network ignoring references to actors at the beginning of
#' # comment text
#' activityNetwork <- collectData %>% Create("activity") %>% 
#'                                    AddText(collectData, replies_from_text = FALSE)
#' 
#' # network
#' # activityNetwork$nodes
#' # activityNetwork$edges
#' }
#' 
#' @aliases AddText.actor.youtube
#' @name vosonSML::AddText.actor.youtube
#' @export
AddText.actor.youtube <- function(net, data, replies_from_text = FALSE, at_replies_only = TRUE, ...) {
  net$edges %<>% dplyr::left_join(dplyr::select(data, .data$CommentID, .data$Comment) %>%
                                  dplyr::rename(comment_id = .data$CommentID, vosonTxt_comment = .data$Comment), 
                                  by = c("comment_id"))
  
  # in comment reply to's
  if (replies_from_text) {
    net$edges %<>% dplyr::left_join(dplyr::select(net$nodes, -.data$node_type), by = c("from" = "id"))
    vid_comments <- dplyr::select(net$edges, .data$video_id, .data$vosonTxt_comment) %>% purrr::transpose()
      
    net$edges$at_id <- sapply(vid_comments, function(x) {
      for (name_at in net$nodes$screen_name) {
        if (at_replies_only) {
          name_at_regex <- paste0("^", Hmisc::escapeRegex(paste0("@", name_at)))
        } else {
          name_at_regex <- paste0("^[@]?", Hmisc::escapeRegex(name_at))
        }
        
        if (grepl(name_at_regex, x$vosonTxt_comment)) {
          to_id <- dplyr::filter(net$edges, .data$screen_name == name_at & .data$video_id == x$video_id) %>%
                   dplyr::select(.data$from) %>% dplyr::distinct()
          if (nrow(to_id)) { return( as.character(tail(to_id, n = 1)) ) } # choose last match - best effort
        }
      }
      return(as.character(NA))
    })
    net$edges %<>% dplyr::mutate(to = ifelse(is.na(.data$at_id), .data$to, .data$at_id), 
                                 edge_type = ifelse(is.na(.data$at_id), .data$edge_type, "reply-comment-text")) 
    # , at_id = NULL # leave in for reference
  }
  
  class(net) <- union(class(net), c("voson_text"))
  cat("Done.\n")
  
  net
}

#' @title Add columns containing text data to reddit actor network dataframes
#' 
#' @param net A named list of dataframes \code{nodes} and \code{edges} generated by \code{Create}.
#' @param data A dataframe generated by \code{Collect}.
#' @param cleanText Logical. Simple removal of problematic characters for XML 1.0 standard. Implemented to prevent
#' reddit specific XML control character errors when generating graphml files. Default is \code{TRUE}.
#' @param ... Additional parameters passed to function. Not used in this method.
#' 
#' @return Network as a named list of two dataframes containing \code{$nodes} and \code{$edges}
#' including columns containing text data.
#'
#' @aliases AddText.actor.reddit
#' @name vosonSML::AddText.actor.reddit
#' @export
AddText.actor.reddit <- function(net, data, cleanText = FALSE, ...) {

  # rename the edge attribute containing the thread comment
  net$edges <- dplyr::left_join(net$edges,
                                dplyr::select(data, .data$subreddit, .data$thread_id, .data$id, .data$comment),
                                by = c("subreddit", "thread_id", "comment_id" = "id")) %>%
               dplyr::rename(vosonTxt_comment = .data$comment)

  authors <- dplyr::select(data, .data$subreddit, .data$thread_id, .data$title, .data$post_text) %>% 
    dplyr::distinct() %>% dplyr::mutate(comment_id = 0)
  
  net$edges <- dplyr::left_join(net$edges, authors, by = c("subreddit", "thread_id", "comment_id")) %>%
    dplyr::mutate(vosonTxt_comment = ifelse(.data$comment_id == 0, .data$post_text, .data$vosonTxt_comment), 
                  post_text = NULL)
  
  net$edges$vosonTxt_comment <- ifelse(trimws(net$edges$vosonTxt_comment) == "", NA, net$edges$vosonTxt_comment)
  
  if (cleanText) {
    net$edges$vosonTxt_comment <- CleanRedditText(net$edges$vosonTxt_comment)
    net$edges$title <- CleanRedditText(net$edges$title)
  }
  
  class(net) <- union(class(net), c("voson_text"))
  cat("Done.\n")
  
  net
}
