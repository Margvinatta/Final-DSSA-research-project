# Margvinatta Senesie
# DSSA Final Project:- Kaggle Nutrition dataset
# Load required libraries
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(cluster)
library(factoextra)
library(fmsb)
library(wordcloud2)
library(corrplot)
library(proxy)
library(stopwords)
# Load data
df <- read_excel("nutrition.xlsx")

#removing the first column
df <- df %>% select(-`...1`)

# Basic cleaning: remove unnamed index column
df <- df %>% select(-matches("^Unnamed"))

# Clean numeric columns: remove units and convert to numeric
clean_numeric <- function(x) {
  x <- gsub("[^0-9.]", "", x) # remove non-numeric characters
  as.numeric(x)
}
# want to know the names of the columns
colnames(df)

# Apply cleaning to nutrient columns
nutrient_cols <- c(
  "calories", "total_fat", "saturated_fat", "cholesterol", 
  "sodium", "choline", "folic_acid", "protein", 
  "carbohydrate", "calcium", "irom", "vitamin_c", 
  "vitamin_a", "fat", "sugars", "water"
)

df <- df %>%
  mutate(across(all_of(nutrient_cols), clean_numeric, .names = "clean_{.col}"))

# Create a healthiness score (example: high protein + low fat + low sodium)
df <- df %>%
  mutate(health_score = clean_protein - (clean_total_fat + clean_sodium / 100))

# Top 10 healthiest items based on score
top_healthy <- df %>%
  select(name, health_score) %>%
  arrange(desc(health_score)) %>%
  head(10)

print("Top 10 Healthiest Foods:")
print(top_healthy)

# Plot: Calories vs Protein
ggplot(df, aes(x = clean_calories, y = clean_protein)) +
  geom_point(color = "blue", alpha = 0.7) +
  labs(title = "Calories vs Protein", x = "Calories", y = "Protein (g)")

# Plot: Fat vs Sodium
ggplot(df, aes(x = clean_total_fat, y = clean_sodium)) +
  geom_point(color = "red", alpha = 0.6) +
  labs(title = "Fat vs Sodium", x = "Total Fat (g)", y = "Sodium (mg)")

# Cluster foods based on main nutrients
# Filter only complete rows for clustering
cluster_data <- df %>%
  select(name, starts_with("clean_")) %>%
  drop_na()

# Scale selected columns only
cluster_scaled <- scale(cluster_data %>% select(-name))

# K-means clustering
set.seed(42)
km <- kmeans(cluster_scaled, centers = 3)

# Create a new dataframe with cluster results
clustered <- cluster_data %>%
  select(name) %>%
  mutate(cluster = factor(km$cluster))

# Join cluster labels back to full dataset by food name
df <- df %>%
  left_join(clustered, by = "name")

# this ensures continuity with your existing dataset
cleaned_data <- df

# Plot clusters
fviz_cluster(km, data = cluster_scaled,
             palette = c("#00AFBB", "#E7B800", "#FC4E07"),
             geom = "point", ellipse.type = "convex", 
             ggtheme = theme_minimal())

# Bar chart: Average nutrients by cluster
cluster_means <- df %>%
  filter(!is.na(cluster)) %>%  # removes unassigned rows
  group_by(cluster) %>%
  summarise(across(starts_with("clean_"), mean, na.rm = TRUE))

print("Average Nutrients by Cluster:")
print(cluster_means)

# PHASE 1: Cluster Interpretation
# Radar Chart of Cluster Means
radar_data <- cluster_means %>%
  select(-cluster) %>% 
  scale() %>%
  as.data.frame()

rownames(radar_data) <- paste0("Cluster ", cluster_means$cluster)

radar_ready <- rbind(apply(radar_data, 2, max),
                     apply(radar_data, 2, min),
                     radar_data)

radarchart(radar_ready, axistype = 1, title = "Radar Chart of Clusters")

# Word Cloud for Cluster Labels (with stopwords removed)
# Word Cloud for Cluster Labels (with stopwords removed)
for (i in unique(df$cluster)) {
  cluster_names <- df %>% filter(cluster == i) %>% pull(name)
  words <- tolower(unlist(strsplit(paste(cluster_names, collapse = " "), " ")))
  
  # Remove stopwords and blank strings
  words <- words[!words %in% stopwords::stopwords("en")]
  words <- words[nzchar(words)]  # remove empty strings
  
  # Check if there's more than 1 word to visualize
  if (length(unique(words)) > 1) {
    word_freq <- as.data.frame(table(words), stringsAsFactors = FALSE)
    colnames(word_freq) <- c("word", "freq")
    wordcloud2(word_freq, size = 0.6)
  } else {
    message(paste("Skipping cluster", i, "- not enough words for wordcloud"))
  }
}

# PHASE 2: Trend Analysis
cor_matrix <- cor(df %>% select(starts_with("clean_")), use = "complete.obs")
corrplot(cor_matrix, method = "color", type = "upper")

# PCA
# Filter full dataset to match rows used in PCA
pca_data <- df %>%
  filter(!is.na(cluster)) %>%              # Remove rows without a cluster
  drop_na(starts_with("clean_"))           # Remove rows with missing nutrients

# Extract numeric nutrient matrix
nutrient_only <- pca_data %>%
  select(starts_with("clean_"))

# Run PCA
pca <- prcomp(nutrient_only, scale. = TRUE)

# Plot with correct habillage
fviz_pca_biplot(pca, label = "var", habillage = pca_data$cluster, addEllipses = TRUE)

# PHASE 3: Cosine Similarity Recommender
# Compute cosine distance matrix and convert to square matrix
nutrient_matrix <- df %>%
  select(starts_with("clean_")) %>%
  drop_na() %>%
  scale() %>%
  as.matrix()

# Calculate cosine distances
similarity_dist <- proxy::dist(nutrient_matrix, method = "cosine")

# Convert to full matrix
similarity_matrix <- as.matrix(similarity_dist)


# Recommend similar foods
# Pick any food row index (e.g., 100)
food_index <- 100

# Find most similar items by sorting (excluding itself)
similar_items <- order(similarity_matrix[food_index, ])[2:21]  # returns 20 most similar foods

# Use the same filtered df to match rows with nutrient_matrix
df_clean <- df %>% drop_na(starts_with("clean_"))

# View recommended alternatives
recommended <- df_clean[similar_items, c("name", "health_score", "cluster")]
print(recommended)

# Find a food with high health_score
healthy_df <- df %>%
  drop_na(starts_with("clean_")) %>%
  filter(health_score > 10)  # or choose a different threshold

# Show top few healthy rows with row numbers
healthy_preview <- healthy_df %>%
  mutate(row_index = as.numeric(rownames(.))) %>%
  select(row_index, name, health_score) %>%
  arrange(desc(health_score)) %>%
  head(10)

print(healthy_preview)

# Pick any food row index (e.g., 100)
food_index1 <- 517

# Find most similar items by sorting (excluding itself)
similar_items1 <- order(similarity_matrix[food_index1, ])[2:21] # returns 20 most similar foods

# Use the same filtered df to match rows with nutrient_matrix
df_clean1 <- df %>% drop_na(starts_with("clean_"))

# View recommended alternatives
recommended1 <- df_clean1[similar_items, c("name", "health_score", "cluster")]
print(recommended1)



#cat("\n🍽️ Top 20 similar foods:\n"
#print(recommended)
