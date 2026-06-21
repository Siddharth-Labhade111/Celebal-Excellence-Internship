# Shopping Dataset Analysis

## Project Overview

This project focuses on performing Exploratory Data Analysis (EDA), data cleaning, feature engineering, and extracting meaningful insights from a shopping product dataset.

The objective is to understand product pricing patterns, customer ratings, popularity trends, and category-level performance using Python.

---

## Dataset

Dataset Used:

`Combined_dataset.csv`

The dataset contains product-level information such as:

* Product name
* Category
* Initial price
* Final price
* Ratings
* Number of ratings
* Other product details

---

## Technologies Used

* Python
* Pandas
* NumPy
* Matplotlib
* Seaborn
* Jupyter Notebook

---

## Project Workflow

### 1. Data Loading

* Imported required Python libraries
* Loaded the shopping dataset
* Checked dataset size and column information

---

### 2. Data Understanding

Performed:

* Dataset shape analysis
* Column inspection
* Data type checking
* Statistical summary using describe()

---

### 3. Data Cleaning

Performed:

* Converted price columns into numeric format
* Handled missing values
* Removed duplicate records
* Verified cleaned dataset quality

---

### 4. Feature Engineering

Created new analytical features:

### Price Difference

Formula:

```
price_difference = initial_price - final_price
```

This helps analyze discount impact.

### Popularity Metric

Formula:

```
popularity_metric = rating × ratings_count
```

This helps identify popular products based on customer engagement.

---

### Data Selection Operations

Performed data selection using Pandas:

- loc[] for label-based filtering and selecting required columns.
- iloc[] for index-based row and column selection.
- Applied conditional filtering to extract meaningful subsets of data.


## Exploratory Data Analysis

Performed:

### Univariate Analysis

* Price distribution
* Rating distribution

### Bivariate Analysis

* Rating vs price relationship
* Discount impact analysis

### Category Analysis

* Product count by category
* Average price by category

---

## Visualizations

Created visualizations using:

* Histograms
* Bar charts
* Scatter plots
* Boxplots

These visualizations help identify:

* Pricing trends
* Customer preferences
* Product performance

---

## Key Insights

* Product prices vary significantly across categories.
* Customer ratings do not always depend on product price.
* Popular products are influenced by both ratings and number of reviews.
* Discount analysis helps identify attractive offers.
* Category analysis helps understand market distribution.

---

## Project Structure

```
shopping-analysis/

│── data/
│   └── cleaned_combined_dataset.csv

│── notebook/
│   └── Shopping_Dataset_EDA_Cleaning.ipynb

│── README.md

│── requirements.txt
```

---

## Author

Siddharth Labhade
