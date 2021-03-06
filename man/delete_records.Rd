% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/page_records.R
\name{delete_records}
\alias{delete_records}
\title{Delete records}
\usage{
delete_records(server_name, profile_id, access_token, page_id, record_ids)
}
\arguments{
\item{server_name}{String of the iFormBuilder server name.}

\item{profile_id}{Integer of the iFormBuilder profile ID.}

\item{access_token}{Access token produced by \code{\link{get_iform_access_token}}}

\item{page_id}{ID of the page from which to delete the record.}

\item{record_ids}{Integer vector of the record IDs to delete.}
}
\value{
Integer vector of the deleted record IDs.
}
\description{
Delete a list of records.
}
\author{
Bill Devoe, \email{William.DeVoe@maine.gov}
}
