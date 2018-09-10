#' Sync table
#'
#' Syncs a dataframe with the contents of an IFB page. If the page does
#' not yet exist, it will be created and populated with the source data.
#'
#' An example use case is syncing an existing database table with a
#' Smart Table Search form in IFB. All columns in the source data
#' with matching columns in the form data are synced. Data is synced
#' in a parent-to-child fashion:
#' - Rows in the source data not in the form data are added (based on
#' the unique identifier from the \code{uid} argument.)
#' - Rows in the form data that are not prseent in the source data
#' can be optionally removed using the \code{delete} argument.
#' - Rows in the form data are updated if any of their fields differ
#' from the matching row in the source data. Updating can be disabled
#' by passing False to the \code{update} argument.
#'
#' @rdname sync_table
#' @author Bill Devoe, \email{William.DeVoe@@maine.gov}
#' @param server_name String of the iFormBuilder server name.
#' @param profile_id Integer of the iFormBuilder profile ID.
#' @param access_token Access token produced by \code{iformr::get_iform_access_token}
#' @param data A dataframe containing the data to be synced with the page.
#' @param form_name The name of a page to sync the source data to; if the page does
#' not exist, it will be created.
#' @param label *Optional* - String of the label to be used if a new page is created.
#' If a label is not provided and a new page is created, the form_name argument will
#' be used to create a page label.
#' @param uid The name of the column in the source and IFB data that uniquely identifies
#' a record.
#' @param update *Optional* Defaults to True - If True, records in the form data
#' will be updated if the matching record in the source data is different.
#' @param delete *Optional* Defaults to False - If True, records in the form data
#' not present in the source data will be removed.
#' @return The page ID of the existing or created form.
#' @examples
#' \dontrun{
#' # Get access_token
#' access_token <- get_iform_access_token(
#'   server_name = "your_server_name",
#'   client_key_name = "your_client_key_name",
#'   client_secret_name = "your_client_secret_name")
#'
#' # Add new data to form
#' sync_table(server_name, profile_id, access_token,
#'   data = "new_dataframe", form_name = "my_form",
#'   uid = "unique_id_col")
#' }
#' @export
#' @import methods
#' @import dplyr
sync_table <- function(server_name, profile_id, access_token,
                       data, form_name, label, uid, update = T,
                       delete = F){
  # Convert the dataframe to be Smart Table search friendly -
  # Date fields to UNIX epoch string, everything else to string
  is.Date <- function(x) inherits(x, c("POSIXct", "POSIXlt", "POSIXt", "Date"))
  data <- dplyr::mutate_if(data, is.Date(data), as.numeric)
  data <- dplyr::mutate_if(data, !is.Date(data), as.character)
  # Get a list of all the pages in the profile
  page_list <- iformr::get_all_pages_list(server_name, profile_id, access_token)
  # Remove whitespace, punctuation, etc from name
  form_name <- tolower(gsub('([[:punct:]])|\\s+','_', form_name))
  # If the form does not exist, create it
  if (form_name %in% page_list$name == F){
    message("Form ",form_name," does not yet exist.")
    # If form label has not been provided, create a label from the form name
    if (methods::missingArg(label)) {
      label <- stringr::str_to_title(gsub('_',' ', form_name))
    }
    # Create page for table data
    page_id <- iformr::data2form(server_name, profile_id, access_token,
                                 name = form_name, label, data)
  }
  else {
    # Get id of existing page
    page_id <- page_list[page_list$name == form_name ,]$id
  }
  # If something goes wrong with request
  stopifnot(page_id > 0)
  # Field names of input table to lowercase to match IFB
  names(data) <- tolower(names(data))
  # Fields names in source table
  src_flds <- names(data)
  # Get list of elements in existing page
  ifb_flds <- iformr::retrieve_element_list(server_name, profile_id, access_token,
                                            page_id, fields = 'label')
  # Fields in page from elements dataframe
  ifb_flds <- ifb_flds$name
  # Fields in source table also in page
  flds <- intersect(src_flds, ifb_flds)
  # Fields in both tables collapsed to string
  fldstr <- paste(flds, collapse = ',')
  # Check that UID column is in both datasets
  uid <- tolower(uid)
  if (!(uid %in% src_flds))
  {stop(paste0("UID column ",uid," is missing from source data."))}
  if (!(uid %in% ifb_flds))
  {stop(paste0("UID column ",uid," is missing from IFB data."))}
  # Pull all data in IFB table
  i_data <- iformr::get_all_records(server_name, profile_id, page_id, fields = "fields",
                                    limit = 1000, offset = 0, access_token,
                                    field_string = fldstr, since_id = 0)
  # If there is data in IFB
  if (nrow(i_data) > 0) {
    # Find data in source table that is not in IFB table
    new_data <- dplyr::anti_join(data, i_data, by=uid)
    # Remove columns from source table not in IFB table
    new_data <- new_data[ , (names(new_data) %in% flds)]
  }
  else {
    new_data <- data
  }
  # Upload new data to IFB
  message(paste0(nrow(new_data), " new records will be added to ",form_name))
  upload <- create_new_records(server_name, profile_id, page_id,
                               access_token, record_data = new_data)
  # Remove data from IFB if delete option is true
  if (delete == T) {
    # UIDs in form data NOT in source data
    del_data <- dplyr::anti_join(i_data, data, by=uid)
    message(paste0(nrow(del_data), " records will be removed from ",form_name))
    #TODO: call to function to remove
  }
  # Update data in IFB if update option true
  if (update == T) {
    # Natural anti-join gets all records where fields do not match
    up_data <- dplyr::anti_join(data, i_data)
    # Filter by unique uid
    up_data <- dplyr::distinct(up_data, uid)
    message(paste0(nrow(up_data), " records will be updated in ",form_name))
    #TODO: call to update data
  }
}


#' Form metadata
#'
#' Builds a Markdown document containing metadata for a given
#' iFormBuilder form by querying the API for page and element
#' level information. By utilizing the description fields during
#' form building, detailed metadata can be built afterward using
#' this function.
#'
#' @rdname form_metadata
#' @author Bill Devoe, \email{William.DeVoe@@maine.gov}
#' @param server_name String of the iFormBuilder server name.
#' @param profile_id Integer of the iFormBuilder profile ID.
#' @param access_token Access token produced by \code{iformr::get_iform_access_token}
#' @param page_id ID of the form to get metadata from.
#' @param filename Filename of the output Markdown file.
#' @param subforms **Optional** - Indicates if metadata should be generated for subforms.
#' Defaults to True.
#' @param sub  **Optional** - Defaults to False. Used by function to self-reference
#' and append subform metadata to beginning file.
#' @return Add this later.
#' @examples
#' \dontrun{
#' # Get access_token
#' access_token <- get_iform_access_token(
#'   server_name = "your_server_name",
#'   client_key_name = "your_client_key_name",
#'   client_secret_name = "your_client_secret_name")
#'
#' # Add new data to form
#' sync_table(server_name, profile_id, access_token,
#'   data = "new_dataframe", form_name = "my_form",
#'   uid = "unique_id_col")
#' }
#' @export
#' @import tidyr
#' @import knitr
#' @import dplyr
form_metadata <- function(server_name, profile_id, access_token,
                          page_id, filename, subforms=T, sub=F) {
  # If not appending subform data to an existing file
  if (sub == F) {
    # Add Markdown extension if it was not provided
    if (!(endsWith(filename, ".md")) || !(endsWith(filename, ".Rmd"))) {
      filename <- paste0(filename,".md")
    }
    # Create/overwrite output file
    file.create(filename)
  }
  # Get metadata for page
  page <- iformr::retrieve_page(server_name, profile_id, access_token, page_id)
  elements <- iformr::retrieve_element_list(server_name, profile_id, access_token, page_id)
  # Convert date columns
  page$created_date <- iformr::idate_time(page$created_date, Sys.timezone())
  page$modified_date <- iformr::idate_time(page$modified_date, Sys.timezone())
  elements$created_date <- iformr::idate_time(elements$created_date, Sys.timezone())
  elements$modified_date <- iformr::idate_time(elements$modified_date, Sys.timezone())
  # Convert data type to label
  data_types <- list("1" = "Text", "2" = "Number", "3" = "Date",
                     "4" = "Time", "5" = "Date-Time", "6" = "Toggle",
                     "7" = "Select", "8" = "Pick List", "9" = "Multi-Select",
                     "10" = "Range", "11" = "Image", "12" = "Signature",
                     "13" = "Sound", "15" = "Manatee Works", "16" = "Label",
                     "17" = "Divider", "18" = "Subform", "19" = "Text Area",
                     "20" = "Phone", "21" = "SSN", "22" = "Email",
                     "23" = "Zip Code", "24" = "Assign To", "25" = "Unique ID",
                     "28" = "Drawing", "30" = "Magstripe", "31" = "RFID",
                     "32" = "Attachment", "33" = "Read Only", "35" = "Image Label",
                     "37" = "Location", "38" = "Socket Scanner", "39" = "Linea Pro",
                     "42" = "ETI Thermometer", "44" = "ESRI", "45" = "3rd Party",
                     "46" = "Counter", "47" = "Timer")
  elements$data_type <- unlist(data_types[as.character(elements$data_type)], use.names = F)
  # Replace option list IDs with option list name
  # TODO: Add this.
  # Replace blank fields with NA so they will not be added to metadata
  elements[elements == ''] <- NA
  # Blank vector for subform IDs
  subs <- c()
  # Open md file connection
  conn <- file(filename, 'a')
  # Write form title
  if (sub == F) {
    cat("# Parent Form: ",page$label,"\n",file=conn)
  }
  else {
    cat("# Sub Form: ",page$label,"\n",file=conn)
  }
  # Collapse page detail list to table
  page_data <- do.call(rbind, page)
  page_data <- data.frame(Value=page_data[,1])
  # Write page table to md file
  md <- knitr::kable(page_data, format = 'markdown')
  cat(md, sep = "\n", file = conn)
  # For each element, write a table to the md document
  cat("## Element Details\n", file = conn)
  for (row in 1:nrow(elements)) {
    # Element label
    label <- elements[row, 'label']
    # Element type
    type <- elements[row, 'data_type']
    # If a subform, append subform page id (data_size) to subform list
    if (type == 'Subform') {
      subs <- c(subs, elements[row, 'data_size'])
    }
    # Subsample element dataframe to element
    element <- elements[row,]
    # Gather element columns to rows
    field <- tidyr::gather(element, key = "Attribute", value = "Value",
                           na.rm = T, convert = FALSE, factor_key = FALSE)
    rownames(field) <- c()
    # Write to markdown file
    cat("### ", label, "\n", file = conn)
    md <- knitr::kable(field, format = 'markdown')
    cat(md, sep = "\n", file = conn)
    cat("\n", file = conn)
  }
  # Self-reference function to build subform metadata
  for (sub in subs) {
    form_metadata(server_name, profile_id, access_token,
                  page_id=sub, filename, subforms = T, sub = T)
  }
  # Close file connection
  close(conn)
}

#' Create form from dataframe
#'
#' Creates a form based on a dataframe. Dataframe classes are cast as
#' element types in the form.
#'
#' @rdname data2form
#' @author Bill Devoe, \email{William.DeVoe@@maine.gov}
#' @param server_name String of the iFormBuilder server name.
#' @param profile_id Integer of the iFormBuilder profile ID.
#' @param access_token Access token produced by \code{iformr::get_iform_access_token}
#' @param name String of new page name; coerced to iFormBuilder
#'   table name conventions.
#' @param label String of the label for the new page.
#' @param data A dataframe whose structure will be used to
#'   create the new form.
#' @return The page ID of the created form.
#' @examples
#' # Create a dataframe with some basic form fields
#' dat = tibble::tibble(survey_id = NA_integer_,
#'                      survey_datetime = as.POSIXct(NA, tz = "UTC"),
#'                      surveyor = NA_character_,
#'                      start_point = NA_real_,
#'                      fish_species = NA_integer_,
#'                      fish_count = NA_integer_,
#'                      end_point = NA_real_,
#'                      comment_text = NA_character_,
#'                      survey_completed = TRUE)
#'
#' \dontrun{
#' # Get access_token
#' access_token <- get_iform_access_token(
#'   server_name = "your_server_name",
#'   client_key_name = "your_client_key_name",
#'   client_secret_name = "your_client_secret_name")
#'
#' # Create new form from dataframe
#' new_form <- data2form(
#'   server_name = "your_server_name",
#'   profile_id = "your_profile_id",
#'   access_token = access_token,
#'   name = "new_form_to_create",
#'   label = "New form based on an R dataframe",
#'   data = dat)
#' }
#' @export
data2form = function(server_name, profile_id, access_token,
                     name, label, data) {
  # Remove whitespace, punctuation, etc from name
  name <- tolower(gsub('([[:punct:]])|\\s+','_', name))
  # Create empty form
  page_id <- create_page(server_name, profile_id, access_token, name, label)
  # Get field classes of input data
  field_classes <- sapply(data, class)
  # List mapping data classes to IFB element types
  ifb_types <- list("character" = 1, "numeric" = 2, "integer" = 2,
                    "double" = 2, "POSIXct" = 5, "logical" = 6)
  # For each field in input data
  for (field in names(field_classes)) {
    # Class of field
    class <- field_classes[[field]][1]
    # ifb element type for field
    data_type <- ifb_types[[class]]
    # Label as proper case
    label <- gsub('_',' ', field)
    label <- stringr::str_to_title(label)
    # Add element to page
    create_element(server_name, profile_id, access_token, page_id,
                   name=field, label, description="", data_type)
  }
  return(page_id)
}