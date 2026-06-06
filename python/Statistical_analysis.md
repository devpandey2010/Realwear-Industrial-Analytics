# Statistical Analysis Narrative
**Project:** RealWear Industrial Operations Analytics & Smart Factory Intelligence System
**Tool:** Python (scipy, pandas, numpy, statsmodels)
**Dataset:** 12,000 sessions | 5 Plants | 20 Devices | Jan 2025 – Jan 2026
**Notebook:** `04_python/notebooks/01_statistics.ipynb`

---

## 1. Setup & Data Loading

### What We Did
- Imported all required statistical libraries: `numpy`, `pandas`, `seaborn`, `matplotlib`, `scipy.stats`, `sqlite3`, `statsmodels`
- Loaded data directly from SQLite database (`realwear.db`) into pandas DataFrames
- Loaded 3 tables: `Master_Session_Log`, `Worker_Master`, `Device_Health_Log`

### Result
```
Master Session Log: 12,000 rows × 30 columns
- 12 Numeric columns
- 18 Categorical columns
- 0 DateTime columns (Session_Date loaded as object)
- No missing values in any column 
```

---

## 2. Column Classification

### Approach
Used a `for` loop to iterate through all columns and classify based on `dtype`:
- `int64` / `float64` → Numeric
- `object` → Categorical
- `datetime64[ns]` → DateTime

### Result
```
Numeric Columns (12):
  → Meeting_Duration_min
  → Resolution_Time_min
  → Command_Attempts
  → Command_Failures
  → Command_Success_Rate
  → Noise_Level_dB
  → Signal_Strength_dBm
  → Battery_Start_%
  → Battery_End_%
  → battery_drain_percent
  → Downtime_Saved_min
  → Productivity_Score

Categorical Columns (18):
  → Session_ID, Session_Date, Shift, Plant_Location,
    Plant_Zone, Department, Worker_ID, Worker_Role,
    Device_ID, Platform, Issue_Type, Issue_Priority,
    Connection_Type, Internet_Strength, External_Mic_Used,
    Issue_Resolved, Session_Status, Incident_Reported
```

---

## 3. Descriptive Statistics

### What We Did
Computed extended descriptive statistics for all 12 numeric columns:
- Standard stats: count, mean, std, min, 25%, 50%, 75%, max
- Extended stats: skewness, median, variance, CV% (Coefficient of Variation)

### What is CV%?
```
CV% = (Standard Deviation / Mean) × 100

Purpose: Measures relative variability — allows comparison 
across columns with different scales and units.

Interpretation:
< 15%  → Low variability (consistent data)
15-30% → Moderate variability
> 30%  → High variability (inconsistent data)
```

### Results
```
Column                   Mean    Std     Skewness  CV%
Meeting_Duration_min     29.89   14.59   0.02      48.81%
Resolution_Time_min      49.26   29.05   0.63      58.97%
Command_Attempts         27.28   10.44   0.02      38.26%
Command_Failures         5.60    4.58    1.15      81.84%
Command_Success_Rate     79.91   13.63   -0.53     17.06%
Noise_Level_dB           81.39   20.99   -0.00     25.78%
Signal_Strength_dBm      -61.47  13.89   -0.00     -22.60%
Battery_Start_%          70.11   17.61   -0.02     25.12%
Battery_End_%            58.08   18.45   -0.02     31.77%
battery_drain_percent    12.47   5.51    -0.00     44.15%
Downtime_Saved_min       49.75   26.08   0.01      52.41%
Productivity_Score       77.50   14.80   -0.52     19.09%
```

### Key Observations
- **Command_Failures has highest CV% (81.84%)** — most inconsistent metric across sessions
- **Command_Success_Rate has lowest CV% (17.06%)** — most consistent metric
- **Command_Failures is right skewed (1.15)** — most sessions have low failures but few sessions have very high failures
- **Productivity_Score is slightly left skewed (-0.52)** — most workers perform above average
- **Resolution_Time_min has high CV% (58.97%)** — resolution time varies significantly across sessions

---

## 4. Normality Testing

### Why We Need This
Before applying any statistical test we must verify whether data follows a normal distribution:
- **Parametric tests** (T-Test, ANOVA) → require normally distributed data
- **Non-Parametric tests** (Mann-Whitney, Kruskal-Wallis) → no normality assumption needed

### Test Used: Shapiro-Wilk
- Most powerful normality test for sample sizes under 5,000
- We sampled 5,000 rows from 12,000 because with full dataset Shapiro-Wilk becomes oversensitive and detects even tiny deviations as non-normal

### Hypotheses
```
H0: Data is normally distributed
H1: Data is not normally distributed
Significance Level: α = 0.05
```

### Results (Before Transformation)
```
Column                   Stat    P-Value   Normal?
Meeting_Duration_min     0.9540  0.0000    No 
Resolution_Time_min      0.9526  0.0000    No 
Command_Attempts         0.9502  0.0000    No 
Command_Failures         0.8907  0.0000    No 
Command_Success_Rate     0.9436  0.0000    No 
Noise_Level_dB           0.9567  0.0000    No 
Signal_Strength_dBm      0.9524  0.0000    No 
Battery_Start_%          0.9564  0.0000    No 
Battery_End_%            0.9762  0.0000    No 
battery_drain_percent    0.9553  0.0000    No 
Downtime_Saved_min       0.9544  0.0000    No 
Productivity_Score       0.8463  0.0000    No 
```
**All columns rejected H0 → None are normally distributed **

---

## 5. Log Transformation Attempt

### Why We Tried This
Log transformation is commonly used to normalize right-skewed data:
```
np.log1p(x) = log(1 + x)
```
Note: `log1p` used instead of `log` because `log(0) = undefined` while `log1p(0) = 0`

### Results (After Log Transformation)
```
All columns still returned p = 0.0000 → Still not normal 
```

### Why This Happened
Real world industrial data with 12,000 rows rarely follows perfect normal distribution because:
- Command failures have natural lower bound at 0
- Productivity scores are capped at 100
- Resolution time has extreme outliers (complex issues)
- Battery readings have physical boundaries

---

## 6. Central Limit Theorem Verification

### What is CLT?
> "When sample size > 30, the sampling distribution of the mean approaches normality regardless of the original data distribution"

Since data is not normal, we invoke CLT to justify using parametric tests — but only if all groups have sufficient sample sizes.

### Results
```
Platform Groups:
  MS Teams : 8,189 samples → CLT APPLIES 
  Webex    : 3,811 samples → CLT APPLIES 

Shift Groups:
  Afternoon (14:00-22:00) : 4,031 → CLT APPLIES 
  Morning (06:00-14:00)   : 3,964 → CLT APPLIES 
  Night (22:00-06:00)     : 4,005 → CLT APPLIES 

Plant Groups:
  Bokaro Manufacturing Hub  : 2,433 → CLT APPLIES 
  Chennai Refinery Unit     : 2,432 → CLT APPLIES 
  Jamshedpur Steel Plant    : 2,403 → CLT APPLIES 
  Pune Automation Plant     : 2,421 → CLT APPLIES 
  Vadodara Chemical Unit    : 2,311 → CLT APPLIES 

Noise Category Groups:
  Low    : 4,150 → CLT APPLIES 
  Medium : 2,423 → CLT APPLIES 
  High   : 2,527 → CLT APPLIES 

External Mic Groups:
  No  : 6,380 → CLT APPLIES 
  Yes : 5,620 → CLT APPLIES 
```

### Decision
All groups have n >> 30 → **CLT applies → Parametric tests (ANOVA, T-Test) are justified** 

### Final Testing Strategy
Both parametric and non-parametric tests will be run for robustness:
```
ANOVA        → for 3+ group comparisons
T-Test       → for 2 group comparisons
Effect Size  → alongside every test for practical significance
```

---

## 7. Hypothesis Test 1 — Does Noise Level Affect Command Failures?

### Business Question
Do workers in high noise environments experience more voice command failures in RealWear devices?

### Approach
- **Test:** One Way ANOVA
- **Why ANOVA:** Comparing means across 3 groups (Low/Medium/High noise) — ANOVA is designed for 3+ group comparisons
- **Why not T-Test:** T-Test only handles 2 groups
- **Why not Chi-Square:** Both variables are numeric not categorical
- **Justification:** CLT applies — all noise groups have n > 2,000

### Noise Categories
```
Low Noise    : Noise_Level_dB ≤ 70 dB
Medium Noise : 70 < Noise_Level_dB ≤ 85 dB
High Noise   : Noise_Level_dB > 85 dB
```

### Hypotheses
```
H0: Noise level has no significant effect on command failures
    μ_low = μ_medium = μ_high
H1: Noise level has significant effect on command failures
    At least one group mean is significantly different
Significance Level: α = 0.05
```

### ANOVA Results
```
F-Statistic  : 153.3946
P-Value      : 0.000000
Decision     : Reject H0 
```

### Effect Size (Eta Squared)
```
Formula: η² = SS_between / SS_total

η² = 0.0326
Interpretation: Small effect
```

### Post-Hoc Test: Tukey HSD
Since ANOVA only tells us "at least one group is different" but not WHICH groups differ, we ran Tukey HSD:
```
Comparison        Mean Diff   P-Adj   Significant?
High vs Low       -1.8602     0.000   Yes 
High vs Medium    -1.2253     0.000   Yes 
Low vs Medium      0.6348     0.000   Yes 
```
**All three pairs are significantly different from each other.**

### Business Interpretation
- Noise level statistically significantly affects command failures (p < 0.05) 
- However the effect size is **small (η² = 0.0326)** — noise explains only 3.26% of total variance in command failures
- High noise environments have on average **1.86 more failures** than low noise environments
- All three noise levels are significantly different from each other

### Conclusion & Recommendation
> Noise level has a statistically significant but practically small effect on command failures. While the difference is real, other factors likely explain the majority of command failures. **Recommendation: Investigate additional factors (connection type, device health, signal strength) before investing heavily in noise reduction solutions.**

---

## 8. Hypothesis Test 2 — Is MS Teams Better Than Webex?

### Business Question
Does MS Teams deliver significantly higher productivity scores than Webex for RealWear industrial sessions?

### Approach
- **Test:** Welch's Independent T-Test (one-tailed)
- **Why T-Test:** Comparing means of exactly 2 groups (MS Teams vs Webex)
- **Why Welch's:** Does not assume equal variances between groups — more robust than standard T-Test
- **Why one-tailed:** We have a directional hypothesis — MS Teams is hypothesized to be BETTER not just different

### Hypotheses
```
H0: Average productivity of MS Teams ≤ Average productivity of Webex
H1: Average productivity of MS Teams > Average productivity of Webex
Significance Level: α = 0.05
```

### Group Sizes
```
MS Teams : 8,189 sessions → CLT APPLIES 
Webex    : 3,811 sessions → CLT APPLIES 
```

### Results
```
T-Statistic  : [result from notebook]
T-Critical   : [result from notebook]
Degrees of Freedom (Welch): [result from notebook]
Decision     : [Reject / Fail to Reject H0]
```
*(Update with actual values after running)*

### Business Interpretation
*(To be filled after running the test)*

### Conclusion & Recommendation
*(To be filled after running the test)*

---

HYPOTHESIS TEST 3: IS NIGHT SHIFT PRODUCTIVITY SIGNIFICANTLY HIGHER?

HO: NO SIGNIFICANT DIFFERENCE IN PRODUCTIVITY ACROSS SHIFTS

HA:ATLEAST ONE SHIFT HAS SIGNIFICANTLY DIFFERENT PRODUCTIVITY

TEST:ONE WAY ANOVA
SIGNIFICANCE LEVEL:0.05

Business Recommendation:

Statistical analysis reveals no significant difference in productivity across Morning, Afternoon and Night shifts (F=0.512, p=0.599, η²=0.0001). Management should not make shift-based operational changes to improve productivity. Resources should instead be directed toward investigating other factors such as plant location, device health and noise levels which may have stronger influence on productivity.

IMPORTANT FINDING:

Excel showed night shift as most productive but 
ANOVA confirmed differences are statistically 
insignificant (p=0.599) and practically negligible (η²=0.0001)
This demonstrates the critical importance of statistical 
validation beyond surface level observations


Hypothesis Test 4 — Does External Mic Make a Difference?

H0: External mic has no significant effect on command failures

H1: External mic significantly reduces command failures

Test: Welch Independent T-Test (one-tailed)
Significance Level: α = 0.05 

IMPORTANT FINDING:

External mic users show MORE failures (6.21) vs non-users (5.05)
This is NOT because external mic causes failures
Confounding variable identified: Noise Level
Workers use external mic in high noise environments
where failures are already higher regardless of mic usage
This is a classic confounding variable problem
Proper analysis requires controlling for noise level


Hypothesis Test 5 — Does Plant Location Affect Productivity?

H0: No significant difference in productivity across plants

H1: At least one plant has significantly different productivity

Test: One Way ANOVA + Tukey HSD
Significance Level: α = 0.05

Plant location shows no statistically significant effect on productivity (F=2.038, p=0.086, η²=0.0007). However the borderline p-value suggests there may be a weak underlying difference between plants that our current sample size of 12,000 cannot conclusively confirm. Bokaro shows highest productivity (78.04) while Chennai and Vadodara are lowest (77.15) — a difference of only 0.89 points. Recommended action: Monitor plant differences over time and retest with larger dataset before making plant-specific operational decisions."


Note in statistics_narrative.md:
Plant productivity differences are statistically 
insignificant (p=0.086) but borderline — 
suggesting weak underlying differences that 
may become significant with larger dataset.
Statistical power analysis recommended.

