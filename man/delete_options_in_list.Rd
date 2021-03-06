% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/option_lists.R
\name{delete_options_in_list}
\alias{delete_options_in_list}
\title{Delete all or some options in an option list}
\usage{
delete_options_in_list(server_name, profile_id, optionlist_id,
  fields = "fields", id_values, limit = 1000, offset = 0,
  access_token)
}
\arguments{
\item{server_name}{The server name as encoded in the url:
`https//server_name.iformbuilder.com`}

\item{profile_id}{The id number of your profile}

\item{optionlist_id}{The id number for the option list}

\item{fields}{Placeholder for fields to delete, not yet implemented}

\item{id_values}{A .json list of ids for elements to delete}

\item{limit}{The maximum number of option elements to delete}

\item{offset}{Skips the offset number of options before beginning to delete}

\item{access_token}{The access_token required to establish communication with
the API}
}
\value{
A vector of option list elements that were deleted
}
\description{
Sends a request to the iFormBuilder API to delete a list of option elements.
The elements to delete are specified by a .json list of element ids. Sort
order will automatically be reassigned after deleting specified elements.
}
\examples{
\dontrun{
# Define .json list of ids for elements to delete
# Replace example values below with your own
  id_values = data_frame(id = c(663487010, 663487013))
  id_values_json = jsonlite::toJSON(id_values, auto_unbox = TRUE)

# Get access_token
access_token <- get_iform_access_token(
  server_name = "your_server_name",
  client_key_name = "your_client_key_name",
  client_secret_name = "your_client_secret_name")

# Delete specified elements from option list
deleted_ids <- delete_options_in_list(
  server_name = "your_server_name",
  profile_id = 123456,
  optionlist_id = your_option_list_id,
  id_values = id_values_json,
  access_token = access_token)

# Inspect the first five deleted ids
head(deleted_ids, 5)
}
}
