# Local Shiny App
# Final DSSA Project
# Smart Bites Recommender by Margvinatta Senesie
# I tried running the shiny app and getting a url but i counldn't due to
# "Warning: The select input "food_choice" contains a large number of options"
library(shiny)
library(readxl)
library(dplyr)
library(wordcloud2)
library(proxy)
library(stopwords)
library(DT)
library(stringr)

# Load & Clean Data 
df <- read_excel("nutrition.xlsx") %>%
  select(-`...1`) %>%
  select(-matches("^Unnamed"))

clean_numeric <- function(x) {
  x <- gsub("[^0-9.]", "", x)
  as.numeric(x)
}

nutrient_cols <- c(
  "calories", "total_fat", "saturated_fat", "cholesterol", 
  "sodium", "choline", "folic_acid", "protein", 
  "carbohydrate", "calcium", "irom", "vitamin_c", 
  "vitamin_a", "fat", "sugars", "water"
)

df <- df %>%
  mutate(across(all_of(nutrient_cols), clean_numeric, .names = "clean_{.col}")) %>%
  mutate(health_score = clean_protein - (clean_total_fat + clean_sodium / 100))

#  Add Category Column (basic keyword-based)
df <- df %>%
  mutate(category = case_when(
    str_detect(tolower(name), "cereal|granola|oat") ~ "Cereals",
    str_detect(tolower(name), "chicken|turkey|beef|meat|pork") ~ "Meats",
    str_detect(tolower(name), "snack|chips|cracker") ~ "Snacks",
    str_detect(tolower(name), "vegetable|carrot|spinach|broccoli") ~ "Vegetables",
    str_detect(tolower(name), "fruit|banana|apple|berries|peach") ~ "Fruits",
    str_detect(tolower(name), "cookie|cake|muffin|donut|brownie") ~ "Desserts",
    str_detect(tolower(name), "egg") ~ "Eggs",
    TRUE ~ "Other"
  ))

#  Filter complete nutrient rows 
df_clean <- df %>%
  filter(if_all(starts_with("clean_"), ~ !is.na(.))) %>%
  mutate(row_id = row_number())

#  Clustering
cluster_data <- df_clean %>%
  select(name, starts_with("clean_"))

cluster_scaled <- scale(cluster_data %>% select(-name))
set.seed(42)
km <- kmeans(cluster_scaled, centers = 3)
df_clean$cluster <- factor(km$cluster)

#Cosine Similarity
nutrient_matrix <- df_clean %>%
  select(starts_with("clean_")) %>%
  scale() %>%
  as.matrix()

similarity_dist <- proxy::dist(nutrient_matrix, method = "cosine")
similarity_matrix <- as.matrix(similarity_dist)

#UI
ui <- fluidPage(
  titlePanel("Smart Bites: Nutrient-Based Food Recommender"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("category_filter", "Filter by Category:",
                  choices = c("All", sort(unique(df_clean$category))), selected = "All"),
      uiOutput("food_picker"),
      sliderInput("num_results", "Number of Recommendations:", 5, 50, 20),
      checkboxInput("filter_healthier", "Only show healthier options?", TRUE)
    ),
    
    mainPanel(
      h4("Recommended Foods"),
      dataTableOutput("recommend_table"),
      h4("Word Cloud for Selected Food's Cluster"),
      wordcloud2Output("wordcloud"),
      h4("What is the Health Score?"),
      verbatimTextOutput("score_explainer")
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive: Filter foods by category
  foods_in_category <- reactive({
    if (input$category_filter == "All") {
      df_clean
    } else {
      df_clean %>% filter(category == input$category_filter)
    }
  })
  
  # UI: Dropdown menu updates based on selected category
  output$food_picker <- renderUI({
    selectInput("food_choice", "Select a Food Item:",
                choices = foods_in_category()$name)
  })
  
  selected_index <- reactive({
    which(df_clean$name == input$food_choice)[1]
  })
  
  output$recommend_table <- renderDataTable({
    req(input$food_choice)
    idx <- selected_index()
    original_score <- df_clean$health_score[idx]
    similar_items <- order(similarity_matrix[idx, ])[2:100]
    similar_df <- df_clean[similar_items, ]
    
    if (input$filter_healthier) {
      similar_df <- similar_df %>% filter(health_score > original_score)
    }
    
    similar_df %>%
      arrange(desc(health_score)) %>%
      select(name, category, health_score, cluster) %>%
      head(input$num_results)
  })
  
  output$wordcloud <- renderWordcloud2({
    cluster <- df_clean$cluster[selected_index()]
    cluster_names <- df_clean %>% filter(cluster == !!cluster) %>% pull(name)
    words <- tolower(unlist(strsplit(paste(cluster_names, collapse = " "), " ")))
    
    custom_stopwords <- c("cooked", "only", "fat", "beef", "steak", "meat", "roasted", "ready", "to", "eat", "cereal", "chocolate", "dry", "whole", "imported")
    words <- words[!words %in% stopwords::stopwords("en")]
    words <- words[!words %in% custom_stopwords]
    words <- words[nzchar(words)]
    
    if (length(unique(words)) > 1) {
      word_freq <- as.data.frame(table(words), stringsAsFactors = FALSE)
      colnames(word_freq) <- c("word", "freq")
      wordcloud2(word_freq, size = 0.6)
    } else {
      return(NULL)
    }
  })
  
  output$score_explainer <- renderText({
    paste(
      "The health score is a custom metric calculated as:\n\n",
      "    health_score = protein - (total_fat + sodium / 100)\n\n",
      "This means foods with high protein and low fat and sodium get higher scores.\n",
      "Higher values are considered healthier in this context.\n\n",
      "This is a simplified formula to help compare items across clusters.",
      sep = ""
    )
  })
}

# Run App 
shinyApp(ui, server)

