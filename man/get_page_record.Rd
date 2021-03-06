% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/page_records.R
\name{get_page_record}
\alias{get_page_record}
\title{Get a single record from a page (i.e., form, or subform)}
\usage{
get_page_record(server_name, profile_id, page_id, record_id, access_token)
}
\arguments{
\item{server_name}{The server name as encoded in the url:
`https//server_name.iformbuilder.com`}

\item{profile_id}{The id number of your profile}

\item{page_id}{The id for the form}

\item{record_id}{The id for the specific record to return}

\item{access_token}{The access_token required to establish communication with
the API}
}
\value{
Dataframe of a single record from the given form
}
\description{
Sends a request to the iFormBuilder API to get a single record from a form or
subform given a record id.
}
\examples{
\dontrun{
# Get access_token
access_token <- get_iform_access_token(
  server_name = "your_server_name",
  client_key_name = "your_client_key_name",
  client_secret_name = "your_client_secret_name")

# Get the id of a single form in the profile given the form name
form_id <- get_page_id(
  server_name = "your_server_name",
  profile_id = 123456,
  page_name = "your_form_p",
  access_token = access_token)

# Get a list of all record ids in the specified form
record_ids <- get_page_record_list(
  server_name = "your_server_name",
  profile_id = 123456,
  page_id = form_id,
  access_token = access_token)

# Inspect the top five record_ids
head(record_ids, 5)

# Get the first record in the list
single_record_id = record_ids[1]

# Get a single record from a form or subform
single_form_record <- get_page_record(
  server_name = "your_server_name",
  profile_id = 123456,
  page_id = form_id,
  record_id = single_record_id,
  access_token = access_token)

# Inspect the first five columns of the single record dataframe
single_form_record[,1:5]
}
}
