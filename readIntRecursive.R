readinteger <- function(x) {
    input <- readline(prompt = "Enter number of tweets to be processed: ")
    if (!grepl("^[0-9]+$", input)) {
        print("Invalid Integer Input")
        readinteger()
    } else {
        as.integer(input)
    }
}