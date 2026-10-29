# The Auction Room: An IPL Data Analytics Case Study

**SQL | Python | Pandas | Data Analysis**

## Project Overview

The Auction Room is a data analytics project that explores IPL ball-by-ball cricket data to identify batting performance, bowling contributions, team scoring patterns, and match-level trends.

The project approaches the analysis from the perspective of an IPL franchise preparing for an auction. The objective is to turn historical performance data into meaningful insights that can support player evaluation and team strategy.

## Business Objectives

- Analyze overall IPL scoring and match-level patterns.
- Identify leading run scorers and boundary hitters.
- Compare batter strike rates and scoring consistency.
- Evaluate bowler wicket-taking contributions.
- Examine dismissal types and extras.
- Compare team innings totals and over-by-over scoring patterns.
- Develop an initial shortlist of batters for further evaluation.

## Tools and Technologies

- **MySQL 8.0+:** Data querying, aggregations, filtering, CTEs, subqueries, and window functions.
- **Python:** Data cleaning, validation, and exploratory data analysis.
- **Pandas:** Data manipulation and transformation.
- **Jupyter Notebook:** Interactive analysis and documentation.
- **Matplotlib and Seaborn:** Data visualization, where used in the notebook.

## Project Structure

```text
The-Auction-Room-IPL-Analytics/
│
├── IPL_AUCTION_CASE_STUDY.sql
├── jupter_notebook.ipynb
├── dataset/
│   └── cleaned/
│       └── ipl_dataset_cleaned.csv
│
└── README.md
```

*The file and folder names above should match the actual repository structure.*

## SQL Analysis

The SQL analysis is organized into five sections:

### Act 1: Know the League
- Dataset overview and overall performance metrics
- Team scoring averages
- Dot-ball percentage
- Franchise scoring rankings
- Boundary contribution

### Act 2: The Batters
- Top run scorers
- Six hitters and four hitters
- Strike-rate analysis
- Fifties and hundreds
- Highest individual scores

### Act 3: The Bowlers
- Bowler-credited wickets
- Dismissal-type distribution
- Extras analysis
- Bowlers taking wickets across multiple matches

### Act 4: The Rivals and Match Situation
- Highest team innings totals
- Leading run scorer for each franchise
- Over-by-over scoring analysis
- Average runs scored in each over

### Act 5: The Final Shortlist
- Identify batters with a minimum number of counted deliveries.
- Rank potential candidates using historical run-scoring performance.
- Prepare a preliminary shortlist for further evaluation.

## SQL Concepts Demonstrated

- `SELECT`, `WHERE`, and `ORDER BY`
- Aggregate functions: `SUM()`, `COUNT()`, and `AVG()`
- `GROUP BY` and `HAVING`
- `CASE` expressions
- Common Table Expressions (CTEs)
- Subqueries
- Window functions, including `RANK()` and `ROW_NUMBER()`

## Python Analysis

The Python notebook documents the data preparation and exploratory analysis workflow, including:

- Inspecting the dataset structure and data types
- Checking missing values and duplicate records
- Cleaning and standardizing selected fields
- Validating run-related columns
- Preparing a cleaned dataset for further analysis
- Exploring performance patterns through visualizations

## How to Run the Project

### 1. Clone the repository

```bash
git clone https://github.com/Code247nexus/The-Auction-Room-IPL-Analytics.git
cd The-Auction-Room-IPL-Analytics
```

### 2. Run the Python notebook

Open `jupter_notebook.ipynb` in Jupyter Notebook, JupyterLab, or Google Colab.

Install the required libraries if needed:

```bash
pip install pandas numpy matplotlib seaborn jupyter
```

Update the dataset path in the notebook to match your local folder structure.

### 3. Set up MySQL

Create the database and import the cleaned CSV into a table named `ipl_data`. Confirm that the table columns match those used by the SQL script.

```sql
CREATE DATABASE ipl;
USE ipl;

DESCRIBE ipl_data;
```

Import the CSV using MySQL Workbench or another compatible import method, then execute the SQL queries.

## Key Learning Outcomes

- Translating business questions into SQL queries
- Working with structured, delivery-level data
- Applying aggregation and window functions
- Performing data cleaning and validation using Python
- Communicating analytical findings through visualizations
- Structuring a reproducible data analytics project

## Limitations

The available dataset does not include auction prices, player age, bowling pace or spin classifications, match results, or a season column. Therefore, this analysis evaluates historical performance indicators rather than predicting auction prices or determining a player's complete auction value.

## Author

**Aditya Jha**

B.Tech in Artificial Intelligence and Machine Learning

GitHub: [Code247nexus](https://github.com/Code247nexus)

---

*This project is intended for educational and portfolio purposes. Findings should be validated against query results before being used to make business or auction decisions.*
