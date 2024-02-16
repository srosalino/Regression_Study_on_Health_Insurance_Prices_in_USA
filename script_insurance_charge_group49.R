# Master in Data Science and Advanced Analytics
# Statistics for Data Science - 2023-2024

# Group 49: 

# Sebastião Rosalino - 20230372
# Andriani Kakoulli - 20230484
# Guilherme Sá - 20230520
# Sophia Mizinski Ramos - 20230999


# RESEARCH QUESTION

'How do the number of children, geographical region, and gender collectively 
influence health insurance charges in the United States?'


# Importing the necessary libraries and configurations
library(ggplot2)
library(dplyr)
library(gridExtra)
library(corrplot)
library(lmtest)
library(fastDummies)
library(sandwich)
library(car)
library(stargazer)


# DATA EXPLORATION


# Load the "insurance.csv" into the variable 'insurance_df'
insurance_df <- read.csv("insurance.csv")

# Overview of the dataset
str(insurance_df)
summary(insurance_df) 

# Check if the dataset has missing values
if (any(is.na(insurance_df))) {
  print("There are missing values in the dataset.")
} else {
  print("There are no missing values in the dataset.")
}

# Split the dataset into dependent variable and independent variables
dependent_df = insurance_df[, ncol(insurance_df)]
independent_df = insurance_df[, -ncol(insurance_df)]


# a) Numerical variables

# Create the three ggplot plots
plot1 <- ggplot(independent_df, aes(x = age)) +
  geom_histogram(fill = "lightblue", color = "black", bins = 30) +
  labs(title = "Distribution of Age", x = "Value", y = "Frequency")

plot2 <- ggplot(independent_df, aes(x = bmi)) +
  geom_histogram(fill = "lightblue", color = "black", bins = 30) +
  labs(title = "Distribution of BMI", x = "Value", y = "Frequency")

plot3 <- ggplot(independent_df, aes(x = as.factor(children))) +
  geom_bar(fill = "lightblue", color = "black") +
  labs(title = "Distribution of Number Children", x = "Value", y = "Count")

# Arrange the plots in a 1x3 grid
grid.arrange(plot1, plot2, plot3, ncol = 3)


# b) Categorical variables

# Combine the three categorical variables into a long format for ggplot
categorical_variables <- tidyr::gather(independent_df, key = "Category", value = "Value", c(sex, smoker, region))

# Calculate the frequencies for each category
category_percentages <- categorical_variables %>% group_by(Category, Value) %>% summarize(percentage = n() / nrow(insurance_df) * 100)

# Create a bar plot with facets for each categorical variable
ggplot(categorical_variables, aes(x = Value, fill = Value)) +
  geom_bar() +
  geom_text(data = category_percentages, aes(label = sprintf("%.1f%%", percentage), y = percentage), vjust = -0.5) +
  facet_wrap(~ Category, scales = "free_x", ncol = 1) +
  labs(title = "Barplots of Categorical Variables", x = "Category", y = "Count") +
  theme(legend.position = "none")  # Hide legend for better visualization


# c) Dependent variable

# Create a ggplot histogram for the dependent variable
ggplot() +
  geom_histogram(data = as.data.frame(dependent_df), aes(x = dependent_df),
                 fill = "lightblue", color = "black", bins = 30) +
  labs(title = "Distribution of Insurance Charges", x = "Value", y = "Frequency")

# Create a ggplot boxplot for the dependent variable
ggplot(as.data.frame(dependent_df), aes(y = dependent_df)) +
  geom_boxplot(fill = "lightblue", color = "black") +
  labs(title = "Distribution of Insurance Charges", x = "", y = "Value")


# Pearson Correlation among variables

# Extract numerical variables
numerical_vars <- subset(insurance_df, select = sapply(insurance_df, is.numeric))

# Calculate correlation matrix
cor_matrix <- cor(numerical_vars)

# Plot the correlation matrix as a heat map with correlation values
corrplot(cor_matrix, method = "color", type = "upper", tl.col = "black", tl.srt = 45, addCoef.col = "black")


# 1) Age and Charges: There is a moderate positive correlation of 0.299 between 
# age and charges. 
# This suggests that as age increases, health insurance charges tend to increase 
# as well, but not very strongly. The relationship is noticeable but not highly pronounced.

# 2) BMI and Charges: BMI (Body Mass Index) has a weaker positive correlation with 
# charges, at 0.198. This indicates a slight tendency for higher BMI to be associated 
# with higher insurance charges, but the relationship is not very strong.

# 3) Children and Charges: The number of children shows a very weak positive 
# correlation with charges (0.068). This implies that having more children has a 
# minimal influence on the cost of insurance charges. The impact of the number of 
# children on insurance charges is quite limited.

# 4) Age and BMI: The correlation between age and BMI is 0.109, which is weak. 
# This indicates that there is a slight tendency for BMI to increase with age, 
# but the relationship is not substantial.

# 5) Age and Children: There is a very weak positive correlation of 0.042 between 
# age and the number of children. This suggests almost no relationship, indicating 
# that the age of the insured does not significantly relate to the number of
# children they have.

# 6) BMI and Children: BMI and the number of children have a correlation of 
# approximately 0.013, indicating no meaningful relationship. This suggests that 
# BMI is independent of the number of children an individual has.


# DATA PREPROCESSING

# a) Outlier Removal

# Create ggplot boxplots for Age, BMI, and Children
plot_age <- ggplot(independent_df, aes(y = age)) +
  geom_boxplot(fill = "lightblue", color = "black") +
  labs(title = "Boxplot of Age", x = "", y = "Value")

plot_bmi <- ggplot(independent_df, aes(y = bmi)) +
  geom_boxplot(fill = "lightblue", color = "black") +
  labs(title = "Boxplot of BMI", x = "", y = "Value")

plot_children <- ggplot(independent_df, aes(y = children)) +
  geom_boxplot(fill = "lightblue", color = "black") +
  labs(title = "Boxplot of Children", x = "", y = "Value")

# Arrange the plots in a 1x3 grid
grid.arrange(plot_age, plot_bmi, plot_children, ncol = 3)

# Create a ggplot boxplot for the dependent variable
ggplot(as.data.frame(insurance_df), aes(y = dependent_df)) +
  geom_boxplot(fill = "lightblue", color = "black") +
  labs(title = "Distribution of Insurance Charges", x = "", y = "Value")

# Calculate IQR
IQR_charges = IQR(insurance_df$charges, na.rm = TRUE)
Q1 = quantile(insurance_df$charges, 0.25, na.rm = TRUE)
Q3 = quantile(insurance_df$charges, 0.75, na.rm = TRUE)

# Define the bounds for outliers
lower_bound = Q1 - 1.5 * IQR_charges
upper_bound = Q3 + 1.5 * IQR_charges

# Identify outliers
outliers = insurance_df$charges < lower_bound | insurance_df$charges > upper_bound

# Create new dataset without outliers
insurance_df_no_outliers = insurance_df[!outliers, ]

# Outliers are extreme values in a dataset that can significantly influence the 
# results of a linear regression analysis. Here's why removing them might be beneficial, 
# especially when comparing models with and without outliers:

# Reduce Variability: Outliers increase the variability of the dependent variable, 
# leading to less reliable estimates. Removing them can stabilize these estimates.

# Improve Accuracy: Outliers can skew the results, leading to inaccurate interpretations. 
# Eliminating them might help the model to more accurately reflect the typical 
# relationship between variables.

# Assumption Compliance: Linear regression assumes constant variance and normality 
# of errors. Outliers can violate these assumptions, and their removal can help in 
# meeting these criteria.

# Diagnostic Value: Comparing models with and without outliers helps assess their 
# impact and the sensitivity of the model to extreme values.


# b) Fitting a linear regression

linear_regression = lm(data=insurance_df, formula=charges ~ age + sex + bmi
                       + children + smoker + region)

summary(linear_regression)


# c) Creating dummy variables

# For the dataset with outliers:

# Create dummy variables for categorical variables
dummy_cols_df <- dummy_cols(insurance_df, select_columns = c('sex', 'smoker', 'region'), remove_first_dummy = TRUE)

# Identify the names of the newly created dummy variables
new_dummy_vars_names <- setdiff(names(dummy_cols_df), names(insurance_df))

# Select only the newly created dummy columns
new_dummy_vars <- dummy_cols_df[, new_dummy_vars_names, drop = FALSE]

# Append the new dummy variables to the original dataset
insurance_df <- cbind(insurance_df, new_dummy_vars)

# View the updated dataset
head(insurance_df)


# For the dataset without outliers:

# Create dummy variables for categorical variables
dummy_cols_df <- dummy_cols(insurance_df_no_outliers, select_columns = c('sex', 'smoker', 'region'), remove_first_dummy = TRUE)

# Identify the names of the newly created dummy variables
new_dummy_vars_names <- setdiff(names(dummy_cols_df), names(insurance_df_no_outliers))

# Select only the newly created dummy columns
new_dummy_vars <- dummy_cols_df[, new_dummy_vars_names, drop = FALSE]

# Append the new dummy variables to the original dataset
insurance_df_no_outliers <- cbind(insurance_df_no_outliers, new_dummy_vars)

# View the updated dataset
head(insurance_df_no_outliers)


# LINEAR REGRESSION ASSUMPTIONS CONFIRMATIONS

# Assumption 1) There is a linear relationship between the independent variables 
# and the dependent variable

# The RESET test will be performed to assess the model's eventual misspecification

resettest(formula=charges ~ age + sex_male + bmi
          + children + smoker_yes + region_northwest + region_southwest + 
            region_southeast, type = c("fitted"), data = insurance_df)

# The obtained p-value of 2.2e-16, suggest that there is enough statistical evidence
# to reject H0. In another words, the functional form of the model is misspecified.

# Correction:

resettest(formula=charges ~ age + I(age^2) + sex_male + bmi
          + children + smoker_yes + region_northwest + region_southwest + 
            region_southeast, type = c("fitted"), data = insurance_df)

# The obtained p-value of 2.2e-16, suggest that there is enough statistical evidence
# to reject H0. In another words, the functional form of the model is misspecified.

# Correction:

resettest(formula=log(charges) ~ age + I(age^2) + sex_male + log(bmi)
          + children + smoker_yes + region_northwest + region_southwest + 
            region_southeast, type = c("fitted"), data = insurance_df)

# The obtained p-value of 2.2e-16, suggest that there is enough statistical evidence
# to reject H0. In another words, the functional form of the model is misspecified.

# Correction:

resettest(formula=log(charges) ~ age + I(age^2) + I(sex_male * region_northwest) +
            I(sex_male * region_southwest) + I(sex_male * region_southeast) + log(bmi) +
            sex_male + children + smoker_yes + region_northwest + region_southwest + 
            region_southeast, type = c("fitted"), data = insurance_df)

# The obtained p-value of 2.2e-16, suggest that there is enough statistical evidence
# to reject H0. In another words, the functional form of the model is misspecified.

# Correction:

resettest(formula=log(charges) ~ age + I(age^2) + I(sex_male * region_northwest) +
            I(sex_male * region_southwest) + I(sex_male * region_southeast) + log(bmi)
          + children + I(children * region_northwest) + I(children * region_southwest) 
          + I(children * region_southeast) + smoker_yes + region_northwest + region_southwest + 
            region_southeast + sex_male, type = c("fitted"), data = insurance_df)

# The obtained p-value of 2.2e-16, suggest that there is enough statistical evidence
# to reject H0. In another words, the functional form of the model is misspecified.


# It is possible to conclude that the functional form of the linear model is 
# misspecificed. One possible reason of this result is the large sample size.


# Final model with Outliers:

final_lm = lm(formula=log(charges) ~ age + I(age^2) + log(bmi)
              + children + smoker_yes + region_northwest + region_southwest + 
                region_southeast + sex_male + I(smoker_yes * region_northwest) +
                I(smoker_yes * region_southwest) + I(smoker_yes * region_southeast) +
                I(log(bmi) * smoker_yes) + I(children * smoker_yes) +
                I(smoker_yes * sex_male), data = insurance_df)

summary(final_lm)

# Final model without Outliers:

final_lm_no_out = lm(formula=log(charges) ~ age + I(age^2) + log(bmi)
              + children + smoker_yes + region_northwest + region_southwest + 
                region_southeast + sex_male + I(smoker_yes * region_northwest) +
                I(smoker_yes * region_southwest) + I(smoker_yes * region_southeast) +
                I(log(bmi) * smoker_yes) + I(children * smoker_yes) +
                I(smoker_yes * sex_male), data = insurance_df_no_outliers)

summary(final_lm_no_out)


# Adjusted R-squared of model with outliers (0.7905): This value is a measure of 
# the model's explanatory power, adjusted for the number of predictors used. 
# An Adjusted R-squared of 0.7905 is quite high, indicating that approximately 79.05% 
# of the variability in the dependent variable (insurance charges) is explained 
# by the model's independent variables. This high value suggests that the model 
# fits the data well and includes relevant predictors without being overly complex.

# Global Significance of the Model: The F-statistic (337.4) and its associated 
# p-value (< 2.2e-16) assess the overall significance of the model. The very low 
# p-value indicates that the model is statistically significant. This means that 
# there is a very low probability that the observed relationships between the 
# independent variables and the dependent variable are due to random chance.


# Assumption 2) Every observation is random and independent from the rest. 
# This assumption was assumed to be true since there is no evidence of the 
# opposite from the metadata (https://www.kaggle.com/datasets/teertha/ushealthinsurancedataset)


# Assumption 3) No perfect collinearity. In the sample there are no exact linear 
# relationships among the independent variables.


# a) Pearson Correlation among variables

# Extract numerical and integer variables
numerical_and_integer_vars <- insurance_df[sapply(insurance_df, function(x) is.numeric(x) || is.integer(x))]

# Calculate correlation matrix
cor_matrix <- cor(numerical_and_integer_vars)

# Plot the correlation matrix as a heat map
corrplot(cor_matrix, method = "color", type = "upper", tl.col = "black", tl.srt = 45, addCoef.col = "black")

# This assumption is validated since there is no correlation of 1 or -1.


# Assumption 4) Zero conditional mean

# Calculate residuals from the linear model
residuals <- resid(final_lm)

# Calculate fitted (predicted) values from the linear model
fitted_values <- fitted(final_lm)

# Create a dataframe for plotting, containing residuals and fitted values
plot_data <- data.frame(Residuals = residuals, Fitted = fitted_values)

# Create a scatter plot using ggplot
ggplot(plot_data, aes(x = Fitted, y = Residuals)) +
  geom_point() +  # Add points for each observation
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +  # Add a horizontal line at y = 0
  labs(title = "Residuals vs. Fitted Values",  # Add plot title and axis labels
       x = "Fitted Values",
       y = "Residuals") +
  theme_minimal()  # Use a minimal theme for a clean plot appearance


# Observing the plot, it appears that the residuals do not fluctuate randomly 
# around the horizontal line at zero, but instead, they show a distinct pattern 
# or curve. This suggests that the residuals have a systematic component that 
# the model has not captured, which violates the zero conditional mean assumption. 
# Instead of fluctuating randomly around the horizontal line at zero, the residuals 
# exhibit a curve, indicating that the model's predictions are systematically too 
# high or too low at different points along the range of fitted values.

# Violating the zero conditional mean assumption can have several limitations and 
# implications for the regression analysis:

# 1) Biased Estimates: If the zero conditional mean assumption does not hold, 
# the estimates of the regression coefficients may be biased. This means that the 
# model could be systematically overestimating or underestimating the effect of 
# the independent variables on the dependent variable.

# 2) Inefficiency: The standard errors of the coefficient estimates may be 
# inaccurate, leading to incorrect conclusions about the significance of the 
# variables. This can result in an inefficient model where the precision of the 
# coefficient estimates is reduced.

# 3) Predictive Inaccuracy: The model's predictive performance may be compromised, 
# particularly for extrapolation outside the range of observed data. If the model 
# systematically misses certain patterns, predictions for new observations may be 
# consistently off-target.

# 4) Misleading Inferences: The overall inference drawn from the model could be 
# misleading. For example, if policy decisions or business strategies are based 
# on the model's predictions, a violation of this assumption could lead to 
# suboptimal or erroneous decisions.


# Assumption 5) Homoskedasticity


# Breausch-Pagan:
bptest(final_lm)


# White-Test Simplified:
simplified_white_test = bptest(final_lm, ~ fitted.values(final_lm) + I(fitted.values(final_lm)^2))
simplified_white_test


# Both tests indicate a violation of the homoskedasticity assumption (Assumption 5) 
# of the classical linear regression model. This implies that the standard errors 
# of the regression coefficients may be biased, which can lead to incorrect 
# conclusions about the statistical significance of the coefficients. In other 
# words, the usual t-tests and F-tests may not be reliable. Moreover, the 
# efficiency of the OLS estimator is compromised, potentially resulting in less 
# accurate estimates.

# Implications: Violating the homoskedasticity assumption does not bias the 
# coefficient estimates themselves (they remain unbiased), but it does affect the 
# variance of the estimators, making them potentially inefficient. This can be 
# particularly problematic when making inferences or hypothesis tests about the 
# model parameters. The presence of heteroskedasticity suggests that there may 
# be omitted variables, incorrect functional forms, or that the model may need 
# to be otherwise adjusted to better capture the underlying pattern in the data.

# To address this, it was considered to use robust standard errors to correct for
# heteroskedasticity.

robust_final_lm = lm(formula=log(charges) ~ age + I(age^2) + log(bmi)
                     + children + smoker_yes + region_northwest + region_southwest + 
                       region_southeast + sex_male + I(smoker_yes * region_northwest) +
                       I(smoker_yes * region_southwest) + I(smoker_yes * region_southeast) +
                       I(log(bmi) * smoker_yes) + I(children * smoker_yes) +
                       I(smoker_yes * sex_male), data = insurance_df)

summary(robust_final_lm)

# Calculate robust standard errors for model coefficients
coeftest(robust_final_lm, vcov=hccm)


# Assumption 6) The error term is normally distributed: u ~ N(0, sigma_squared)

# Graphical Methods:

# 1) Histogram of Residuals

hist(resid(robust_final_lm), breaks = 'Sturges', main = "Histogram of Residuals", xlab = "Residuals")

# 2) Q-Q Plot (Quantile-Quantile Plot)

qqnorm(resid(robust_final_lm))
qqline(resid(robust_final_lm), col = "red")

# Histogram of Residuals:
# The histogram shows the distribution of the residuals - the differences between 
# the observed values and the values predicted by the model. For the errors to be 
# normally distributed, it would expect to see a bell-shaped curve that is 
# symmetrical around the mean (which should be close to zero if the model is 
# well-fitted). In the provided histogram, the distribution of residuals appears 
# to be centered around zero, suggesting that the mean of the error terms could be 
# close to zero. However, the distribution does not appear perfectly bell-shaped 
# and seems to be slightly skewed to the right, with a longer tail extending 
# towards the positive side. This could indicate a departure from normality.

# Normal Q-Q Plot:
# As a complementary analysis (beyond the scope of the course, that was fulfilled),
# the Q-Q plot compares the quantiles of the residuals with the quantiles of a 
# normal distribution. If the residuals were perfectly normally distributed, the 
# points would lie on the 45-degree reference line. The obtained Q-Q plot shows a 
# deviation from this line, especially at the ends, suggesting that the residuals 
# have heavier tails than a normal distribution. This means there are more extreme 
# values than would be expected if the residuals were truly normal, which is 
# another indication of non-normality.

# Interpretation:
# Both plots suggest that the assumption of normally distributed errors may not 
# hold in this case. The histogram hints at a possible skewness, and the Q-Q plot 
# shows heavier tails than would be expected under normality. While these plots 
# do not conclusively prove non-normality, they do provide evidence that the 
# assumption may be violated.


# Statistical Tests:

# 1) Shapiro-Wilk Test

shapiro.test(resid(robust_final_lm))

# 2) Kolmogorov-Smirnov Test

ks.test(resid(robust_final_lm), "pnorm", mean(resid(robust_final_lm)), sd(resid(robust_final_lm)))

# As a complementary analysis (beyond the scope of the course, that was fulfilled) 
# two additional methods to test the residual normal distribution were conducted: 
# Shapiro-Wilk Test and the Kolmogorov-Smirnov Test.

# Shapiro-Wilk Test:
# The Shapiro-Wilk test resulted in a test statistic (W) of 0.80132 and a p-value 
# that is effectively zero (< 2.2e-16). The test statistic is a measure of how 
# much the sample distribution deviates from a normal distribution; a value of 1 
# would indicate a perfect match to a normal distribution. A p-value this low 
# leads to rejecting the null hypothesis that the residuals are normally distributed. 
# This result suggests that the residuals from the robust_final_lm model significantly 
# deviate from normality.

# Kolmogorov-Smirnov Test: Similarly, the Kolmogorov-Smirnov test yielded a D 
# statistic of 0.19372 with a p-value also less than 2.2e-16. The D statistic 
# measures the maximum distance between the empirical distribution function of the 
# sample and the cumulative distribution function of the reference distribution 
# (in this case, a normal distribution). The extremely low p-value again indicates 
# that the null hypothesis of the residuals being drawn from a normal distribution 
# can be rejected, implying non-normality.

# Interpretation: Both tests indicate a violation of the normality assumption for 
# the error terms in the regression model. This finding is consistent with the 
# visual indications from the histogram and Q-Q plot, which suggested skewness and 
# heavier tails than a normal distribution would exhibit.

# Implications: Violation of the normality assumption can impact the validity of 
# hypothesis testing, such as the significance of coefficients, particularly in 
# smaller samples. However, for larger samples, such as the one under 
# consideration with 1338 observations, the Central Limit Theorem offers a resolution. 
# The theorem posits that the distribution of the estimators can be considered 
# approximately normal regardless of the underlying distribution of the residuals 
# when the sample size is sufficiently large. This asymptotic normality allows 
# for the application of conventional statistical tests, including T-tests, F-tests, 
# and the construction of confidence intervals, thus enabling the performance of 
# robust statistical inference.


# ANSWERING THE RESEARCH QUESTION

stargazer(robust_final_lm, final_lm_no_out, type="text", column.labels=c('With Outliers', 'Without Outliers'), out="models_comparison.html",star.cutoffs = c(0.05, 0.01, 0.001),title="Linear Models")


# Age: The analysis shows a noticeable increase in insurance charges with age 
# (coefficient of age is 0.05376) but at a decreasing rate (coefficient of age 
# squared is -0.0002379). This suggests that while charges go up as individuals 
# get older, the rate of increase slows down over time.

# Body Mass Index (BMI): There's a positive relationship between BMI and 
# insurance charges, as indicated by the coefficient of 0.1352 for log(bmi). 
# This means that higher BMI is associated with higher charges, but the
# relationship is not linear.

# Number of Children: For each additional child, the insurance charges increase 
# (coefficient of 0.1204). This shows a clear trend where individuals with more 
# children face higher charges.

# Smoking Status: Being a smoker significantly increases insurance charges. The 
# coefficient for smoker_yes is 2.707. In practice, this means smokers pay 
# substantially more for insurance.

# Location: Living in different regions affects insurance charges differently.
# Compared to the baseline region (northeast), living in the northwest, southwest, 
# and southeast has coefficients of -0.07797, -0.1844, and -0.1883 respectively, 
# indicating varied impacts on charges based on geographical location.

# Gender: The analysis shows a difference in charges based on gender, with males 
# (coefficient of -0.1055) generally paying less than females, when other factors 
# are held constant.

# Interaction between Smoking and Other Factors:
  
# The interaction between smoking and BMI shows a significant effect (coefficient 
# of 1.255 for I(log(bmi) * smoker_yes)), indicating that the impact of BMI on 
# insurance charges is more pronounced for smokers.
 
# The interaction of smoking with children also affects charges (coefficient of 
# -0.1457 for I(children * smoker_yes)), suggesting a different impact of having 
# children on insurance costs for smokers.

# In summary, the number of children, geographical region, and gender all have 
# statistically significant influences on health insurance charges in the United 
# States, with smoking status being a particularly strong predictor. The presence 
# of outliers affects the magnitude of some coefficients, particularly for smoking 
# status, but the overall patterns of influence remain consistent across both models. 
# The robustness of the model's fit, even after removing outliers, suggests these 
# findings are stable and reliable.

