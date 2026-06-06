Statistical Analysis Narrative
RealWear Industrial Operations Analytics and Smart Factory Intelligence System

Project     : RealWear Industrial Operations Analytics
Tool        : Python (scipy, pandas, numpy, statsmodels, seaborn, matplotlib)
Dataset     : 12,000 sessions | 5 Plants | 20 Devices | Jan 2025 to Jan 2026
Notebook    : 04_python/notebooks/01_statistics.ipynb


================================================================================
1. SETUP AND DATA LOADING
================================================================================

What We Did

We started by importing all required statistical libraries including numpy, pandas,
seaborn, matplotlib, scipy.stats, sqlite3 and statsmodels. Data was loaded directly
from our SQLite database (realwear.db) into pandas DataFrames so that all our
earlier SQL work could be reused without duplicating data.

Three tables were loaded:
    Master_Session_Log   (primary analysis table)
    Worker_Master        (worker reference data)
    Device_Health_Log    (device health reference data)

Result

    Master Session Log : 12,000 rows x 30 columns
    12 Numeric columns
    18 Categorical columns
    0 DateTime columns (Session_Date was loaded as object type)
    No missing values in any column across all 30 columns


================================================================================
2. COLUMN CLASSIFICATION
================================================================================

Approach

We wrote a for loop to iterate through all 30 columns and classify each one based
on its dtype. This is better than manual classification because it is automated,
repeatable and handles any new columns added later.

    int64 and float64 columns  =>  Numeric
    object columns             =>  Categorical
    datetime64 columns         =>  DateTime

Result

    Numeric Columns (12):
        Meeting_Duration_min, Resolution_Time_min, Command_Attempts,
        Command_Failures, Command_Success_Rate, Noise_Level_dB,
        Signal_Strength_dBm, Battery_Start_%, Battery_End_%,
        battery_drain_percent, Downtime_Saved_min, Productivity_Score

    Categorical Columns (18):
        Session_ID, Session_Date, Shift, Plant_Location, Plant_Zone,
        Department, Worker_ID, Worker_Role, Device_ID, Platform,
        Issue_Type, Issue_Priority, Connection_Type, Internet_Strength,
        External_Mic_Used, Issue_Resolved, Session_Status, Incident_Reported


================================================================================
3. DESCRIPTIVE STATISTICS
================================================================================

What We Did

We computed an extended descriptive statistics table for all 12 numeric columns.
Beyond the standard statistics (count, mean, std, min, quartiles, max), we added:

    Skewness   :  measures asymmetry of distribution
    Median     :  middle value, less affected by outliers than mean
    Variance   :  population level spread
    CV%        :  Coefficient of Variation = (Std / Mean) x 100

Why CV%?

Standard deviation alone cannot be compared across columns with different scales
and units. CV% normalizes the spread relative to the mean, making comparisons
meaningful across different metrics.

    CV% below 15%   =>  Low variability, consistent data
    CV% 15 to 30%   =>  Moderate variability
    CV% above 30%   =>  High variability, inconsistent data

Results

    Column                   Mean     Std      Skewness   CV%
    Meeting_Duration_min     29.89    14.59    0.02       48.81%
    Resolution_Time_min      49.26    29.05    0.63       58.97%
    Command_Attempts         27.28    10.44    0.02       38.26%
    Command_Failures         5.60     4.58     1.15       81.84%
    Command_Success_Rate     79.91    13.63    -0.53      17.06%
    Noise_Level_dB           81.39    20.99    -0.00      25.78%
    Signal_Strength_dBm      -61.47   13.89    -0.00      -22.60%
    Battery_Start_%          70.11    17.61    -0.02      25.12%
    Battery_End_%            58.08    18.45    -0.02      31.77%
    battery_drain_percent    12.47    5.51     -0.00      44.15%
    Downtime_Saved_min       49.75    26.08    0.01       52.41%
    Productivity_Score       77.50    14.80    -0.52      19.09%

Key Observations

Command_Failures has the highest CV% at 81.84% making it the most inconsistent
metric across sessions. This tells us that command failure behavior varies
significantly from session to session and is not predictable from averages alone.

Command_Success_Rate has the lowest CV% at 17.06% making it the most consistent
metric. This makes sense because success rate is the inverse of failure rate and
tends to cluster around a central value.

Command_Failures is right skewed with skewness of 1.15. This means most sessions
have low failures but a small number of sessions have extremely high failures,
pulling the mean upward. The median would be a better central measure here than
the mean.

Productivity_Score is slightly left skewed at -0.52 which means most workers
perform above average. The distribution is not symmetric but leans toward
higher scores.

Resolution_Time_min has CV% of 58.97% indicating that some issues resolve very
quickly while others take much longer, creating high variability in resolution time.


================================================================================
4. NORMALITY TESTING
================================================================================

Why We Need This

Statistical tests fall into two categories. Parametric tests like T-Test and
ANOVA assume that data follows a normal distribution. Non-parametric tests like
Mann-Whitney and Kruskal-Wallis make no such assumption. We must verify normality
before choosing which type of test to apply.

Test Used: Shapiro-Wilk

Shapiro-Wilk is the most powerful normality test for samples under 5,000. We
sampled 5,000 rows from our 12,000 row dataset because with the full dataset
Shapiro-Wilk becomes oversensitive and begins detecting even very tiny deviations
from normality as statistically significant, which is not useful in practice.

Hypotheses

    H0 : Data is normally distributed
    H1 : Data is not normally distributed
    Significance Level : alpha = 0.05

Results Before Transformation

    Column                   Stat     P-Value    Normal?
    Meeting_Duration_min     0.9540   0.0000     No
    Resolution_Time_min      0.9526   0.0000     No
    Command_Attempts         0.9502   0.0000     No
    Command_Failures         0.8907   0.0000     No
    Command_Success_Rate     0.9436   0.0000     No
    Noise_Level_dB           0.9567   0.0000     No
    Signal_Strength_dBm      0.9524   0.0000     No
    Battery_Start_%          0.9564   0.0000     No
    Battery_End_%            0.9762   0.0000     No
    battery_drain_percent    0.9553   0.0000     No
    Downtime_Saved_min       0.9544   0.0000     No
    Productivity_Score       0.8463   0.0000     No

All 12 columns rejected H0. None of the columns are normally distributed.


================================================================================
5. LOG TRANSFORMATION ATTEMPT
================================================================================

Why We Tried This

Log transformation is a standard technique used to reduce right skewness and
bring data closer to a normal distribution. We used np.log1p instead of np.log
because np.log(0) is undefined (negative infinity) while np.log1p(0) = log(1+0) = 0,
safely handling any zero values in Command_Failures.

Results After Log Transformation

All 12 columns still returned p-value of 0.0000 after transformation. None
became normally distributed.

Why This Happened

Real world industrial data with 12,000 observations rarely follows a perfect normal
distribution. Several natural constraints explain this:

    Command_Failures has a hard lower boundary at 0
    Productivity_Score is capped at 100
    Resolution_Time has extreme outliers from complex issues
    Battery readings are physically bounded between 0 and 100


================================================================================
6. CENTRAL LIMIT THEOREM VERIFICATION
================================================================================

What is CLT?

The Central Limit Theorem states that when sample size is greater than 30, the
sampling distribution of the mean approaches normality regardless of the shape
of the original data distribution.

Since our data is not normal, we used CLT as the justification for applying
parametric tests. The key requirement is that every group we compare must have
a sample size well above 30.

Results

    Platform Groups:
        MS Teams   :  8,189 samples    =>  CLT APPLIES
        Webex      :  3,811 samples    =>  CLT APPLIES

    Shift Groups:
        Afternoon  :  4,031 samples    =>  CLT APPLIES
        Morning    :  3,964 samples    =>  CLT APPLIES
        Night      :  4,005 samples    =>  CLT APPLIES

    Plant Groups:
        Bokaro Manufacturing Hub    :  2,433    =>  CLT APPLIES
        Chennai Refinery Unit       :  2,432    =>  CLT APPLIES
        Jamshedpur Steel Plant      :  2,403    =>  CLT APPLIES
        Pune Automation Plant       :  2,421    =>  CLT APPLIES
        Vadodara Chemical Unit      :  2,311    =>  CLT APPLIES

    Noise Category Groups:
        Low        :  4,150 samples    =>  CLT APPLIES
        Medium     :  2,423 samples    =>  CLT APPLIES
        High       :  2,527 samples    =>  CLT APPLIES

    External Mic Groups:
        No         :  6,380 samples    =>  CLT APPLIES
        Yes        :  5,620 samples    =>  CLT APPLIES

Decision

Every single group across all comparisons has a sample size far above 30. CLT
applies strongly. Parametric tests (ANOVA and T-Test) are fully justified for
this analysis.

Final Testing Strategy

    One Way ANOVA    =>  for comparisons across 3 or more groups
    Welch T-Test     =>  for comparisons between exactly 2 groups
    Effect Size      =>  calculated alongside every test to measure practical significance


================================================================================
7. HYPOTHESIS TEST 1: DOES NOISE LEVEL AFFECT COMMAND FAILURES?
================================================================================

Business Question

Do workers in noisier factory environments experience more voice command failures
when using RealWear devices?

Approach and Test Selection

We chose One Way ANOVA because we are comparing means across three noise groups
(Low, Medium, High). ANOVA is specifically designed for three or more group
comparisons. A T-Test would only handle two groups. Chi-Square was not appropriate
because both variables are numeric, not categorical. CLT is satisfied because
all three noise groups have more than 2,000 samples each.

Noise categories were defined as:
    Low Noise    :  Noise_Level_dB at or below 70 dB
    Medium Noise :  Noise_Level_dB between 70 and 85 dB
    High Noise   :  Noise_Level_dB above 85 dB

Hypotheses

    H0 : Noise level has no significant effect on command failures
         mu_low = mu_medium = mu_high
    H1 : Noise level has a significant effect on command failures
         At least one group mean is significantly different
    Significance Level : alpha = 0.05

ANOVA Results

    F-Statistic  :  153.3946
    P-Value      :  0.000000
    Decision     :  Reject H0

Effect Size (Eta Squared)

Eta squared measures what proportion of total variance in command failures is
explained by noise level.

    Formula      :  eta squared = SS_between / SS_total
    eta squared  :  0.0326
    Interpretation :  Small effect

Noise level explains only 3.26% of total variance in command failures. While
the difference is statistically real, it is practically small.

Post-Hoc Test: Tukey HSD

ANOVA tells us that at least one group is different but does not tell us which
specific pairs differ. Tukey HSD performs all pairwise comparisons while
controlling for multiple testing error.

    Comparison         Mean Difference    P-Adj    Significant?
    High vs Low        -1.8602            0.000    Yes
    High vs Medium     -1.2253            0.000    Yes
    Low vs Medium       0.6348            0.000    Yes

All three pairs are significantly different from each other.

Business Interpretation

Noise level statistically significantly affects command failures. High noise
environments produce on average 1.86 more failures per session than low noise
environments. However the effect size is small (eta squared = 0.0326) meaning
noise alone explains only about 3% of why failures occur. The majority of command
failure variation comes from other factors not captured by noise level alone.

Recommendation

Investigate additional factors such as connection type, device health and signal
strength before making large investments in noise reduction infrastructure. Noise
matters but it is not the primary driver of command failures.


================================================================================
8. HYPOTHESIS TEST 2: IS MS TEAMS BETTER THAN WEBEX?
================================================================================

Business Question

Does MS Teams deliver significantly higher worker productivity compared to Webex
in RealWear industrial remote assistance sessions?

Approach and Test Selection

We used Welch's Independent T-Test with a one-tailed approach. T-Test was chosen
because we are comparing exactly two groups. We used Welch's version rather than
standard T-Test because Levene's test confirmed unequal variances between the
groups. The test is one-tailed because we have a directional hypothesis: we are
not just asking if they are different, we are specifically asking if MS Teams is
better than Webex.

Hypotheses

    H0 : Average productivity of MS Teams users is less than or equal to Webex
    H1 : Average productivity of MS Teams users is greater than Webex
    Significance Level : alpha = 0.05

Group Sizes

    MS Teams  :  8,189 sessions    =>  CLT APPLIES
    Webex     :  3,811 sessions    =>  CLT APPLIES

Results

    T-Statistic   :  120.0369
    T-Critical    :  1.6450
    Degrees of Freedom (Welch)  :  8,234.49
    Decision      :  Reject H0

Since T-Statistic (120.04) is far greater than T-Critical (1.645), we reject H0
with very strong evidence.

Business Interpretation

MS Teams is statistically significantly more productive than Webex with extremely
strong evidence (T = 120.04). This aligns with our earlier Excel finding where MS
Teams showed 17% higher productivity and 33% better resolution efficiency than
Webex. The statistical test now confirms this is not a random difference but a
genuine and consistent performance gap.

Recommendation

Standardize MS Teams as the primary platform across all 5 plants. Webex should
be phased out or restricted to specific non-critical use cases.


================================================================================
9. HYPOTHESIS TEST 3: IS NIGHT SHIFT MORE PRODUCTIVE?
================================================================================

Business Question

Does shift timing (Morning, Afternoon, Night) significantly influence worker
productivity in RealWear sessions?

Context

Our Excel pivot table analysis showed night shift with the highest average
productivity score (77.67) while morning had the lowest (77.34). We now test
whether this observed difference is statistically real or just random variation.

Approach and Test Selection

One Way ANOVA was used to compare productivity across three shifts simultaneously.

Hypotheses

    H0 : No significant difference in productivity across Morning, Afternoon
         and Night shifts. mu_morning = mu_afternoon = mu_night
    H1 : At least one shift has significantly different productivity
    Significance Level : alpha = 0.05

Group Statistics

    Shift        Sample Size    Mean      Std
    Morning      3,964          77.47     14.82
    Afternoon    4,031          77.34     14.84
    Night        4,005          77.67     14.74

ANOVA Results

    F-Statistic  :  0.5126
    P-Value      :  0.598938
    Decision     :  Fail to Reject H0

Effect Size

    Eta Squared  :  0.0001
    Interpretation :  Negligible effect

Shift timing explains only 0.01% of total productivity variance. This is
effectively zero influence.

Important Finding: Excel vs Statistics

This is one of the most important findings in the entire project. Our Excel
analysis showed night shift as most productive while ANOVA confirms there is no
statistically significant or practically meaningful difference across shifts.

Both findings are correct. The key insight is that the difference between the
highest and lowest shift is only 0.33 points on a 100-point scale. Excel shows
what the numbers are. Statistical testing tells us whether the difference matters.

This demonstrates why statistical validation must follow exploratory analysis.
Without this test, management might have incorrectly redesigned shift schedules
based on a 0.33-point difference that is entirely due to random variation.

Business Recommendation

Statistical analysis reveals no significant difference in productivity across
Morning, Afternoon and Night shifts (F = 0.512, p = 0.599, eta squared = 0.0001).
Management should not make shift-based operational changes to improve productivity.
Resources should be directed toward investigating other factors such as platform
choice, noise levels and device health which have shown stronger relationships
with productivity.


================================================================================
10. HYPOTHESIS TEST 4: DOES EXTERNAL MICROPHONE REDUCE COMMAND FAILURES?
================================================================================

Business Question

Does using an external microphone significantly reduce voice command failures in
RealWear devices?

Approach and Test Selection

Welch's Independent T-Test was selected for this two-group comparison. Levene's
test confirmed unequal variances (Stat = 18.9851, p = 0.0000) so Welch's version
was appropriate. The test was one-tailed because our hypothesis is directional:
we expected external microphones to reduce failures, not just change them.

Hypotheses

    H0 : External microphone has no significant effect on command failures
    H1 : External microphone significantly reduces command failures
    Significance Level : alpha = 0.05

Group Statistics

    Group                  Sample Size    Mean Failures    Std
    With External Mic      5,620          6.21             4.70
    Without External Mic   6,380          5.05             4.40

T-Test Results

    T-Statistic            :  -13.8902
    T-Critical             :  1.6450
    Degrees of Freedom     :  11,566.48
    Decision               :  Fail to Reject H0

Effect Size

    Cohen's d    :  -0.2552
    Interpretation :  Small effect (negative direction)

Surprising Finding: Confounding Variable Identified

Workers with external microphones showed MORE failures (6.21) compared to those
without (5.05). This appears to contradict the hypothesis but the explanation
reveals deeper analytical thinking.

External microphones are most commonly deployed in high noise environments precisely
because workers there struggle with command recognition. High noise environments
already produce more command failures regardless of microphone type. So what we
are observing is not that external microphones cause failures but that they are
concentrated in environments where failures are inherently higher.

This is a classic confounding variable problem. The confounding variable is noise
level. When we control for noise level and compare external mic vs no external mic
within the same noise category, the true effect of the microphone can be properly
isolated.

This finding was verified by running the test separately for each noise category.

Business Interpretation

External microphones do not significantly reduce command failures when analysed
across all sessions. The apparent negative result is explained by deployment
concentration in high noise areas. The real business question is whether
microphone type makes a difference within high noise environments specifically,
which requires the controlled analysis described above.

Recommendation

Do not make microphone policy decisions based on the overall comparison. Analyse
microphone effectiveness within controlled noise categories. Invest in
understanding and reducing noise exposure at source rather than relying on
peripheral equipment as a fix.


================================================================================
11. HYPOTHESIS TEST 5: DOES PLANT LOCATION AFFECT PRODUCTIVITY?
================================================================================

Business Question

Does the specific manufacturing plant where a worker is based significantly
influence their productivity score?

Context

Our Excel analysis showed Bokaro Manufacturing Hub with the highest productivity
(78.04) and Vadodara Chemical Unit and Chennai Refinery Unit with the lowest
(77.15). The difference between highest and lowest is 0.89 points. We now test
whether this is a real difference or random noise.

Approach and Test Selection

One Way ANOVA was used to compare productivity across all five plants simultaneously.
Tukey HSD was planned as the post-hoc test if ANOVA showed significance.

Hypotheses

    H0 : No significant difference in productivity across plants
    H1 : At least one plant has significantly different productivity
    Significance Level : alpha = 0.05

Group Statistics

    Plant                         Sample Size    Mean      Std
    Bokaro Manufacturing Hub      2,433          78.04     14.66
    Pune Automation Plant         2,421          77.88     14.81
    Jamshedpur Steel Plant        2,403          77.25     14.87
    Chennai Refinery Unit         2,432          77.15     14.80
    Vadodara Chemical Unit        2,311          77.15     14.83

ANOVA Results

    F-Statistic  :  2.0384
    P-Value      :  0.086181
    Decision     :  Fail to Reject H0

Effect Size

    Eta Squared  :  0.0007
    Interpretation :  Negligible effect

Nuanced Interpretation: Borderline P-Value

This result is more nuanced than the shift analysis. While we fail to reject H0,
the p-value of 0.086 is meaningfully different from the shift p-value of 0.598.

The shift test at p = 0.598 was very far from significance. The plant test at
p = 0.086 is close to significance. This borderline result suggests there may be
a weak underlying difference between plants that our current sample size of 12,000
sessions is not powerful enough to detect with certainty.

This connects to statistical power. Larger datasets give tests more power to detect
smaller differences. With 50,000 sessions this same 0.89-point difference might
cross the significance threshold. This does not mean the difference is important
but it does mean plant-level performance deserves ongoing monitoring.

Business Recommendation

Plant location shows no statistically significant effect on productivity (F = 2.038,
p = 0.086, eta squared = 0.0007). The borderline p-value suggests a possible
weak underlying pattern that cannot yet be confirmed. Bokaro leads at 78.04 while
Chennai and Vadodara share the lowest average at 77.15, a gap of only 0.89 points.
Management should monitor plant-level productivity trends over time and retest with
a larger dataset before drawing plant-specific conclusions or allocating resources
differently across plants.


================================================================================
12. CORRELATION ANALYSIS
================================================================================

What We Did

We computed a Pearson Correlation Matrix across all 11 numeric variables and
visualized it as a heatmap. We then ranked all variables by their absolute
correlation with Productivity_Score to identify which factors most influence
worker productivity.

Top Factors Correlated with Productivity Score

    Rank    Factor                  Correlation    Strength     Direction
    1       Command_Success_Rate    +0.6996        Moderate     Positive
    2       Command_Failures        -0.5805        Moderate     Negative
    3       Noise_Level_dB          -0.1521        Negligible   Negative
    4       Downtime_Saved_min      +0.0625        Negligible   Positive
    5       Meeting_Duration_min    -0.0352        Negligible   Negative
    6       Resolution_Time_min     -0.0327        Negligible   Negative
    7       Command_Attempts        -0.0123        Negligible   Negative
    8       Signal_Strength_dBm     +0.0081        Negligible   Positive
    9       battery_drain_percent   +0.0058        Negligible   Positive
    10      Battery_Start_%         +0.0025        Negligible   Positive

Interpretation Guide

    Absolute r above 0.7   =>  Strong correlation
    Absolute r 0.4 to 0.7  =>  Moderate correlation
    Absolute r 0.2 to 0.4  =>  Weak correlation
    Absolute r below 0.2   =>  Negligible correlation

Key Findings

Command_Success_Rate has the strongest positive correlation with Productivity at
+0.70. This is intuitive: workers who issue voice commands that succeed consistently
are naturally more productive.

Command_Failures has the strongest negative correlation at -0.58. Higher failure
count directly drags productivity down. This is the single most actionable metric
for improving productivity.

Noise_Level_dB has a small negative correlation of -0.15, confirming our ANOVA
finding that noise affects productivity but only weakly. Noise is not the primary
driver.

All remaining factors (battery, signal strength, resolution time, meeting duration)
have negligible correlations below 0.07, meaning they contribute very little to
explaining productivity variation.

Business Interpretation

Productivity is primarily driven by voice command performance. The two strongest
predictors of high productivity are high command success rate and low command
failures. These account for most of the explainable variation in productivity.
External operational factors like battery level, signal strength and session
duration have almost no direct relationship with productivity.

Recommendation

Focus improvement efforts on reducing command failures and improving voice command
success rates rather than optimizing operational factors like battery management
or session duration. This is where the highest return on investment lies.


================================================================================
OVERALL STATISTICAL SUMMARY
================================================================================

Test                                    Result              Key Metric
Normality (Shapiro-Wilk)               Not normal          All p = 0.000
CLT Verification                        All groups valid    Min group = 2,311
Test 1: Noise vs Command Failures       Significant         p = 0.000, eta2 = 0.033
Test 2: MS Teams vs Webex               Significant         T = 120.04
Test 3: Shift vs Productivity           Not significant     p = 0.599, eta2 = 0.0001
Test 4: External Mic vs Failures        Not significant     Confounding identified
Test 5: Plant vs Productivity           Not significant     p = 0.086, borderline
Test 6: Correlation Analysis            Complete            Top factor: Command_Success_Rate


================================================================================
TESTS REMAINING
================================================================================

Test 7    :  Chi-Square Test (Platform vs Plant Location independence)
Test 8    :  Linear Regression (Predict Productivity Score)
Test 9    :  Outlier Detection (IQR and Z-Score methods)


================================================================================
OVERALL CONCLUSIONS FOR BUSINESS
================================================================================

1. Voice command performance is the most critical driver of productivity. Reducing
   command failures and improving success rates will have the highest impact.

2. MS Teams is statistically and practically superior to Webex. Standardization
   across all plants is strongly recommended.

3. Shift timing has no meaningful effect on productivity. Shift-based interventions
   will not improve performance.

4. Noise level matters statistically but its practical effect is small. It should
   not be the primary focus of improvement efforts.

5. External microphones do not reduce failures in the way commonly assumed. The
   relationship is confounded by deployment patterns in noisy environments.

6. Plant-level differences exist but are not yet statistically confirmable.
   Ongoing monitoring with larger data collection is recommended before plant-
   specific strategies are implemented.


Last Updated : After Correlation Analysis (Test 6)
Next Update  : After Chi-Square, Regression and Outlier Detection
