# installing required packages.
packages.list <- c("twitteR", "ROAuth", "plyr", "stringr", "ggplot2", "RColorBrewer")
uninstalled.packages <- packages.list[sapply(packages.list, function(pckg) !is.element(pckg, installed.packages()[, 1]))]
if (length(uninstalled.packages) > 0) {
    install.packages(uninstalled.packages, dependencies = TRUE)   
}

# loading libraries into environment.
lapply(packages.list, library, character.only=TRUE)

# windows users must download the following file.
# cacert.pem is a bundle of CA certificates that you use to verify that 
# the server is really the correct site you're talking to 
# (when it presents its certificate in the SSL handshake).
if (Sys.info()['sysname'] == 'windows') {
    download.file(url = "http://curl.haxx.se/ca/cacert.pem", destfile = "cacert.pem")    
}

# accessing twitter API.
requestURL <- "https://api.twitter.com/oauth/request_token"
authURL <- "https://api.twitter.com/oauth/authorize"
accessURL <- "https://api.twitter.com/oauth/access_token"
consumerKey <- readline(prompt = "Enter consumerKey of your application : ")
consumerSecret <- readline(prompt = "Enter consumerSecret of your application : ")

Cred <- OAuthFactory$new(consumerKey=consumerKey, consumerSecret=consumerSecret, requestURL=requestURL, authURL=authURL, accessURL=accessURL)
Cred$handshake(cainfo=system.file("CurlSSL", "cacert.pem", package = "RCurl"))

# save the credentials and register
save(Cred, file = "twitter authentication.RData")
load("twitter authentication.RData")
accessToken <- readline(prompt = "Enter access token of your application : ")
accessTokenSecret <- readline(prompt = "Enter access token secret of your application : ")
setup_twitter_oauth(consumer_key = consumerKey, consumer_secret = consumerSecret, access_token = accessToken, access_secret = accessTokenSecret)

# getting tweets from twitter
source("readIntRecursive.R")
topic <- paste("#", readline(prompt = "Enter the topic you wish to perform sentiment analysis WITHOUT HASHTAGS ONLY: "), sep = "")
count <- readinteger()
print(paste("...........Downloading", count, "tweets about", topic, "...........", sep = " "))
tweets.list <- searchTwitter(topic, n = count)
print("Download finished! Converting into appropriate format............")

tweets.df <- twListToDF(tweets.list)
filename <- readline(prompt = "Enter file name for storing the downloaded tweets WITHOUT ANY EXTENSIONS : ")
filenameWithExt <- paste(filename, ".csv", sep = "")
write.csv(tweets.df, file = filenameWithExt, row.names = FALSE)

# get a list of positive and negative words from English and store in a text file.
pos.words <- scan("pos_words.txt", what = 'character', comment.char = ';')
neg.words <- scan("neg_words.txt", what = 'character', comment.char = ';')

# add enhancements to the list of words relevant to the topic
pos.words <- c(pos.words, 'upgrade', 'support')
neg.words <- c(neg.words, 'wtf', 'epicfail', 'mechanical', 'wait', 'waiting')

# read the dataset stored in the csv file
DataSetTweets <- read.csv(filenameWithExt)
DataSetTweets$text <- as.factor(DataSetTweets$text)

# load the sentiment function into the work environment
print("...........Calculating Score of all Tweets...........")
source("SentimentAnalysis.R")

# score all the tweets
DataSetTweets.scores <- score.sentiment(DataSetTweets$text, pos.words = pos.words, neg.words = neg.words)
print("Calculation finished!")

# store the score values in a csv file
write.csv(DataSetTweets.scores, file = paste(filename, ".csv", sep = ""), row.names = TRUE)

# visualize the contents of the file
print(paste("Number of Positive TWEETS = ", length(DataSetTweets.scores$score[DataSetTweets.scores$score > 0]), sep = "")) 
print(paste("Number of Negative TWEETS = ", length(DataSetTweets.scores$score[DataSetTweets.scores$score < 0]), sep = ""))
print(paste("Number of Neutral TWEETS = ", length(DataSetTweets.scores$score[DataSetTweets.scores$score == 0]), sep = ""))
print(summary(DataSetTweets.scores$score))
View(DataSetTweets.scores)
library(RColorBrewer)
numOfColors <- max(DataSetTweets.scores$score) - min(DataSetTweets.scores$score)
hist(DataSetTweets.scores$score, xlab = "Score of Tweets", ylab = "Frequency of Tweets", col = brewer.pal(numOfColors, "Set3"), main = paste("Sentiment Analysis on", filename, sep = " "))