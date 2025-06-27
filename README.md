# Health_care_analysis
Cleaned and analyzed multi-table healthcare data using Pandas and SQL. Identified key issues in treatment delays, cancellations, and cost drivers across departments and demographics. Delivered 24-question analysis with actionable insights to improve healthcare efficiency and patient outcomes.

## 📌 Objective
Analyze healthcare data across appointments, patients, doctors, and treatments to uncover trends in cancellations, treatment costs, doctor performance, and department efficiency.

## 🧰 Tools Used
- SQL (MySQL)
- SQL Views for data cleaning
- GitHub for version control

## 📊 Tables Used
- `appointments`
- `doctors`
- `patients`
- `treatments`

## ✅ Data Validation
- Filtered out treatments where treatment_date < appointment_date
- Set treatment cost = 0 for `Cancelled` and `No-show` appointments using SQL Views

## 🔍 Key Questions Answered (24)
1. Monthly completed vs. cancelled appointments by department (2024)
2. Top 3 symptoms leading to most appointments
3. Average daily appointments by department
4. Day of the week with highest cancellation rate
5. Average wait time between appointment & treatment
6. Top 5 doctors with highest completed appointments
7. Avg treatment cost by doctor specialization
8. Active doctors with no treatments in last 6 months
9. Doctor-city pair generating highest revenue
10. Avg patient age by gender in 2023
11. Avg cost by insurance type
12. City with highest appointments per capita
13. Avg cost: patients over 60 vs under 30
14. Cancellation rate by gender
15. Monthly treatment cost trend by department
16. Top 5 symptoms by avg treatment cost (after cleaning)
17. Which statuses result in zero revenue
18. Monthly revenue trend (2024)
19. Department with highest avg cost per completed appointment
...

## 🧹 Data Cleanup Views
- `treatment_valied_view`: Sets cost to 0 for Cancelled/No-show

## 📄 Summary
See [`Healthcare_Project_Summary.pdf`](./Summary/Healthcare_Project_Summary.pdf) for a one-page breakdown of findings, visuals, and impact.
