# Lab & RPM Metrics API Flow Diagrams

## Lab Metrics Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAB METRICS FLOW                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. FETCH AVAILABLE LAB METRICS                                  │
│    GET /labfolders/metrics/{patientId}                          │
│    Response: List of available metrics with metadata            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. FETCH COMPARISON OPTIONS                                     │
│    GET /lab-available-metric-list/{patientId}                   │
│    Response: { rpm: [...], lab: [...] }                         │
│    - Lists metrics available for comparison dropdown            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. FOR EACH METRIC - FETCH CHART DATA                          │
│    GET /user-lab-metric/{metric}/{patientId}/365                │
│    Response: { data: [[timestamp, val1, val2, val3, ...]],      │
│                average: number }                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. FOR EACH METRIC - FETCH METRIC DETAILS                       │
│    GET /lab-metric-detail/{metric}/{patientId}/{memberId}       │
│    Response:                                                     │
│    {                                                             │
│      detail: { min_range, max_range, optimal_from,              │
│                optimal_thru, default_unit },                     │
│      last: number,           // last reading value              │
│      max_date: string,       // last reading date               │
│      checked: [{ intcount }], // is checked (1=true)            │
│      compared: [{ metric_id, compare_metric_id,                 │
│                    compare_metric_type }]                       │
│    }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. OPTIONAL - COMPARE METRICS                                   │
│    When user selects a metric to compare:                        │
│    PUT /compare-user-lab-metric/{metricId}/{compMetricId}/      │
│        {patientId}/{memberId}/{selectedCategory}                │
│                                                                  │
│    Then fetch chart data for the compared metric                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. OPTIONAL - TOGGLE CHECK MARK                                 │
│    PUT /check-lab-metric/{metricId}/{patientId}/{memberId}      │
└─────────────────────────────────────────────────────────────────┘
```

---

## RPM Metrics Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    RPM METRICS FLOW                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│   MY METRICS SECTION      │   │   CARE TEAM METRICS       │
│   (addedBy = "myMetrics") │   │   (addedBy =              │
│                           │   │    "careTeamMetrics")     │
└───────────────────────────┘   └───────────────────────────┘
                │                           │
                └─────────────┬─────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. FETCH AVAILABLE RPM METRICS                                  │
│    GET /rpm-folders/metrics/{patientId}                         │
│    Response:                                                     │
│    {                                                             │
│      data: [{                                                    │
│        symptoms: string[],           // symptom annotations     │
│        symptomsDates: string[],      // symptom dates          │
│        myMetrics: { [key]: MetricItem },                       │
│        careTeamMetrics: { [key]: MetricItem }                  │
│      }]                                                          │
│    }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. FETCH COMPARISON OPTIONS                                     │
│    GET /lab-available-metric-list/{patientId}                   │
│    Response: { rpm: [...], lab: [...] }                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. FOR EACH METRIC - FETCH CHART DATA                          │
│    GET /usermetric/{metric}/{patientId}/{days}                  │
│    (default days = 365)                                         │
│    Response:                                                     │
│    {                                                             │
│      data: [[timestamp, value]],                                │
│      average: number                                             │
│    }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. FOR EACH METRIC - FETCH METRIC DETAILS                       │
│    GET /metric-description/{metric}/{patientId}/{memberId}      │
│    Response: Same structure as Lab Metric Detail                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. OPTIONAL - SELECT METRICS DIALOG                             │
│    GET /show-all-rpm-metrics/{patientId}                        │
│    Response: List of all metrics with categories                │
│    - availableMetrics: metrics user can add                     │
│    - unavailableMetrics: metrics already added                  │
│                                                                  │
│    SAVE SELECTED:                                                │
│    PUT /save-user-metrics/{patientId}/{memberId}                │
│    Body: { metricIds: number[] }                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. OPTIONAL - COMPARE METRICS                                   │
│    PUT /compare-user-metric/{metricId}/{compMetricId}/          │
│        {patientId}/{memberId}/{selectedCategory}                │
│    selectedCategory: "rpm" or "lab"                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. OPTIONAL - TOGGLE CHECK MARK                                 │
│    PUT /check-user-metric/{metricId}/{patientId}/{memberId}     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Parallel Loading Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                  OPTIMIZED LOADING FLOW                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Fetch metrics list                                      │
│    GET /labfolders/metrics/{patientId}     [Lab]                │
│    GET /rpm-folders/metrics/{patientId}    [RPM]                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: PARALLEL FETCH                                          │
│    ┌─────────────────────┐    ┌─────────────────────┐          │
│    │   Chart Data        │    │   Metric Details    │          │
│    │   (all metrics)     │    │   (all metrics)     │          │
│    │                     │    │                     │          │
│    │   Promise.all()     │    │   Promise.all()     │          │
│    └─────────────────────┘    └─────────────────────┘          │
│                                                                  │
│    Both execute simultaneously for faster load time             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Compare Metrics Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  COMPARE METRICS FLOW                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ User selects metric from dropdown                               │
│ (Options loaded from /lab-available-metric-list/{patientId})   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Determine metric type:                                          │
│    - compare_metric_type = "rpm"  → Use RPM endpoint           │
│    - compare_metric_type = "lab"  → Use Lab endpoint           │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│       RPM METRIC          │   │       LAB METRIC          │
│                           │   │                           │
│ PUT /compare-user-metric/ │   │ PUT /compare-user-lab-    │
│     {metricId}/           │   │     metric/{metricId}/    │
│     {compMetricId}/       │   │     {compMetricId}/       │
│     {patientId}/          │   │     {patientId}/          │
│     {memberId}/rpm        │   │     {memberId}/lab        │
└───────────────────────────┘   └───────────────────────────┘
                │                           │
                └─────────────┬─────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Fetch chart data for compared metric                            │
│    GET /usermetric/{metric}/{patientId}/365       [RPM]        │
│    GET /user-lab-metric/{metric}/{patientId}/365  [Lab]        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Render both charts overlayed                                    │
│ - Primary metric: main chart line                               │
│ - Compared metric: secondary chart line                         │
└─────────────────────────────────────────────────────────────────┘
```
