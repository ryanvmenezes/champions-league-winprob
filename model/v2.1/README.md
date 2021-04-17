# model notes: v2.1

This approach was much simpler: create a different logistic regression model for each minute, and connect the prediction outputs for the 210 different models together. The models were implemented using a straightforward `glm()` call in R.
