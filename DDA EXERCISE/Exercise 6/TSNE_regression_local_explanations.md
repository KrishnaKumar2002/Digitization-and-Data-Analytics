# Add explanations (cells) for `regression_local.ipynb`

Copy the sections below into new markdown cells in **`DDA EXERCISE/Exercise 6/regression_local.ipynb`**.

---

## Task 1 – Correlation Matrices (Answer/Explanation)
**What we did**
- We computed `corr()` for each dataset and visualized it as a heatmap.

**What a correlation matrix tells us**
- Each entry shows how strongly two features move together.
- Values close to **+1**: strong positive linear relation.
- Values close to **−1**: strong negative linear relation.
- Values close to **0**: weak/near-no linear relation.

**Why it matters for ML**
- If multiple features are **strongly correlated**, they may contain overlapping information.
- This can cause **multicollinearity** for linear models and can motivate dimensionality reduction (PCA) later.

**What to write as observation**
- In the **California Housing** dataset, you will typically see strong correlations among some numeric building/area-related measures (often pairs like “rooms” and “population/density” show noticeable positive or negative correlation).
- In the **Cover Type** dataset, the first 10 continuous features used in the heatmap often show weaker correlations overall, but some pairs may still stand out.

---

## Task 2 – PCA (Principle Component Analysis) (Answer/Explanation)
**What we did**
- Standardized features using `StandardScaler()`.
- Fit PCA on the standardized data (separately for regression and classification).
- Plotted a **scree plot** of cumulative explained variance.

**Why standardization is critical**
- PCA is based on variance; different feature scales distort the principal directions.
- Standardization ensures each feature contributes fairly.

**How to decide number of PCs**
- Look at the cumulative explained variance curve.
- Choose the smallest number of components `q` such that cumulative variance ≥ **90%** (the red dashed line in your plot).

**What to observe**
- For both datasets, you should see the cumulative curve rising quickly at first.
- After some number of components, additional PCs contribute diminishing returns.

**Write-up template (fill in with your numbers)**
- *Regression (California Housing):* “We need about **__q_reg__** principal components to reach ≥ 90% explained variance.”
- *Classification (Cover Type):* “We need about **__q_cla__** principal components to reach ≥ 90% explained variance.”

**Comparison with Task 1**
- Correlation matrix showed redundancy.
- PCA identifies new orthogonal directions that capture most of the variance—effectively compressing redundant/collinear information.

---

## Task 3 – t-SNE (Answer/Explanation)
**What we did**
- Used `TSNE(n_components=2)` on a random subset (`sample_size = 2000`).
- Plotted two scatter plots:
  - California Housing colored by **house value**
  - Cover Type colored by **class**

**What t-SNE is (short)**
- A **non-linear** dimensionality reduction method optimized for **visualizing local neighborhoods**.

**Important properties**
- It tries to keep **similar points close** in the embedding.
- Distances in the t-SNE map are not guaranteed to correspond to meaningful “global” distances.
- Results depend on hyperparameters (e.g., *perplexity*) and randomness.

**How to interpret your plots**
- If points form **distinct blobs**, this suggests non-linear clusters in the original space.
- For regression (continuous target), coloring by house value may show that “similar” regions correspond to similar values.
- For classification, colored blobs indicate that different cover types occupy different regions in feature space.

**Note about “t-SNE + supervised model”**
- t-SNE is designed primarily for visualization, not for producing stable, generalizable features for downstream prediction.
- So t-SNE coordinates can look great but may not give good R²/accuracy when used for regression/classification.

---

## Task 4 – Linear Regression (Answer/Explanation)
**What we did**
- Built and evaluated:
  1. Standard Linear Regression
  2. Linear Regression with backward selection via **RFE**
  3. Principal Component Regression (PCA → Linear Regression)
  4. Regression on the t-SNE embedding (visual embedding → model)

**How to interpret R² and MSE**
- `R²` (coefficient of determination):
  - closer to **1** = better fit
  - near **0** = model explains little variance
  - negative values can happen when the model is worse than predicting the mean
- `MSE` measures average squared error (lower is better).

**What to write about “good fit vs bad fit”**
- If R² is high and MSE is low → good fit.
- If R² is low → bad fit (model not capturing the underlying relationship).

**Expected trends**
- Standard Linear Regression often performs decently if the relationship is close to linear.
- RFE can improve or worsen results:
  - can help remove noisy/irrelevant features
  - but may discard features needed for prediction
- PCA Regression may help if redundancy/noise exists:
  - using fewer components can reduce overfitting
- t-SNE Regression often underperforms PCA-based methods because:
  - t-SNE preserves neighborhoods for visualization, not predictive global structure.

---

## Task 5 – Logistic Regression (Answer/Explanation)
**What we did**
- Built and evaluated:
  1. Standard Logistic Regression
  2. RFE Logistic Regression
  3. PCA Logistic Regression (PCA → Logistic)
  4. Logistic Regression on t-SNE embedding

**How to interpret “accuracy” and confusion matrix**
- Accuracy: fraction of correct predictions.
- Confusion matrix:
  - diagonal cells = correct classification
  - off-diagonal = misclassifications

**Good fit vs bad fit**
- High accuracy and many counts on the diagonal → good fit.
- Low accuracy and heavy off-diagonal counts → bad fit.

**Expected trends**
- PCA often provides a stronger, more model-friendly representation than t-SNE.
- RFE can help by reducing dimensionality, but choosing too few features can hurt.
- t-SNE embedding can lead to unstable predictive performance due to its visualization objective.

---

## Extra: “Is it something wrong here?” (Direct answer block)
In your notebook, nothing is syntactically incorrect. The code runs.

However, the methodology note is:
- Using **t-SNE embeddings as features** for regression/classification is usually not recommended, because t-SNE is not designed for preserving predictive distances/geometry.

A better comparison is:
- PCA (good for downstream modeling)
- vs t-SNE (good for plotting)

---

## Optional: Drop-in cell text for your notebook (very short)
**t-SNE + supervised model note:**
> t-SNE mainly preserves local neighborhoods for visualization. Therefore, using t-SNE coordinates as input to Linear/Logistic Regression may not yield reliable predictive performance. PCA is more appropriate when building predictive models.

