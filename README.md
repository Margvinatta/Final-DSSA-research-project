# Final-DSSA-research-project

Unsupervised clustering and food recommender system using nutrient data from the SmartBites dataset (R-based analysis for DSSA practicum project).

# Final DSSA Research Project: Smart Bites

## Overview
This project analyzes 8,789 food items to identify healthier alternatives based on nutrient composition. It uses **k-means clustering** to group foods, **PCA and radar charts** for interpretation, and **cosine similarity** to recommend healthier substitutions.

**Dataset Source:**  
[Kaggle - Nutrition Dataset](https://www.kaggle.com/datasets/gokulprasantht/nutrition-dataset)

## Column Descriptions
The dataset includes nutrient information per food item, with the following key columns (cleaned and standardized for analysis):

- `calories`: Total energy (kcal)
- `total_fat`: Total fat content (g)
- `saturated_fat`: Saturated fat (g)
- `cholesterol`: Cholesterol (mg)
- `sodium`: Sodium content (mg)
- `choline`: Choline (mg) – supports brain and liver health
- `folic_acid`: Folic acid (µg) – important for cell growth
- `protein`: Protein content (g)
- `carbohydrate`: Total carbohydrates (g)
- `calcium`: Calcium (mg)
- `iron` : Iron (mg)
- `vitamin_c`: Vitamin C (mg)
- `vitamin_a`: Vitamin A (IU or µg)

## Key Features
- Nutrient cleaning and standardization
- Health score formula for ranking
- K-means clustering (k = 3)
- PCA biplot and radar chart visualizations
- Cosine similarity–based recommendation engine

## How to Run
1. Open `nutrition_analysis.R` in RStudio.
2. Make sure required libraries (e.g., `dplyr`, `ggplot2`, `factoextra`) are installed.
3. Run each section or the full script.
4. Outputs will be visible in plots and printed tables.

## Tools Used
- R (version 4.4.1)
- `dplyr`, `ggplot2`, `cluster`, `factoextra`, `fmsb`, `corrplot`, `wordcloud2`, `proxy`

## Author
**Margvinatta Senesie**  
Stockton University | DSSA Final Practicum  
August 2025
