% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/option_lists.R
\name{get_option_lists}
\alias{get_option_lists}
\title{Get a listing of all option lists in a profile}
\usage{
get_option_lists(server_name, profile_id, limit = 1000, offset = 0,
  access_token)
}
\arguments{
\item{server_name}{The server name as encoded in the url: `https//server_name.iformbuilder.com`}

\item{profile_id}{The ID number of your profile}

\item{limit}{The maximum number of option lists to return}

\item{offset}{Skips the offset number of options before beginning to return}

\item{access_token}{The access_token required to establish communication with the API}
}
\value{
A listing of all option lists in the given profile
}
\description{
Sends a request to the iFormBuilder API to get a listing of all
option lists currently posted in the given profile.
}