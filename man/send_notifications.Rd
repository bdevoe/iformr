% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/notifications.R
\name{send_notifications}
\alias{send_notifications}
\title{Send notifications}
\usage{
send_notifications(server_name, profile_id, access_token, message, users)
}
\arguments{
\item{server_name}{String of the iFormBuilder server name.}

\item{profile_id}{Integer of the iFormBuilder profile ID.}

\item{access_token}{Access token produced by \code{\link{get_iform_access_token}}}

\item{message}{String containing the message to send.}

\item{users}{Numerical vector containing one or more user IDs,
ie c(1234, 3456)}
}
\value{
Vector of the user IDs that were successfully notified.
}
\description{
Sends a notification to a user or users. Core API call [Send Notifications](
https://iformbuilder.docs.apiary.io/#reference/notification-resource/notification/send-notifications)
}
\author{
Bill Devoe, \email{William.DeVoe@maine.gov}
}
