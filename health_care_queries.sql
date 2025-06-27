use health_care;
show tables;
select * from appointments;
select * from doctors;
select * from patients;
select * from treatments;

select status,count(status)  
from appointments
group by status;

#1how many appointments were completed vs cancelled in each department per month in 2024
SELECT 
    department,
    appointment_month,
    COUNT(CASE
        WHEN status = 'completed' THEN 1
    END) AS completed_appointments,
    COUNT(CASE
        WHEN status = 'cancelled' THEN 1
    END) AS cancelled_appointments
FROM
    appointments
WHERE
    appointment_year = 2024
GROUP BY department , appointment_month
ORDER BY department , appointment_month;

delete from appointments
where appointment_year = 0;

#2which 3 symptoms lead to the highest number of appointments overall?
select * from appointments;
select symptoms, count(*) as no_of_appointments
from appointments
group by symptoms
order by no_of_appointments desc
limit 3;

#3what is the avg no of appointments per day for each department?
select department, round(count(*) / count(distinct appointment_date), 2) as avg_appointment_per_day
from appointments
group by department
order by avg_appointment_per_day desc;

#4which weekday has the highest cancellation rate?
select * from appointments;
select appointment_day as week_day, count(appointment_day) as total_appointments,
count(case when status = 'cancelled' then 1 end ) as cancelled,
round(count(case when status = 'cancelled' then 1 end )*100/count(*),2) as cancellation_rate
from appointments
group by week_day 
order by cancellation_rate desc;

#5what is the avg wait time(in days) between appointment_date and treatment_date by department./
#NOTE1 : Wait time anomalies appeared only when sorting by descending order — indicating data outliers (e.g., 700-day delays). 
#NOTE2 : A filter was applied to remove extreme cases beyond 120 days, allowing more meaningful average and median calculations./
#Discovered data quality issues where some treatment dates were recorded before the appointment date. Applied validation filters 
#across all queries to ensure treatment occurs only after a completed appointment, improving the accuracy and intgrity of the analysis.
SELECT 
    department,
    ROUND(AVG(DATEDIFF(t.treatment_date, a.appointment_date)),
            2) AS avg_wait_time_days
FROM
    appointments a
        JOIN
    treatment_valid_view t ON a.appointment_id = t.appointment_id
WHERE
    DATEDIFF(t.treatment_date, a.appointment_date) <= 120
        AND a.status = 'Completed'
        AND t.treatment_date >= a.appointment_date
GROUP BY a.department
ORDER BY avg_wait_time_days;

#6which 5 doctors have the highest number of completed appointments in the last 12 months
SELECT 
    d.doctor_name, COUNT(*) AS no_of_appointments
FROM
    doctors d
        JOIN
    appointments a ON a.doctor_id = d.doctor_id
    join  treatment_valid_view t
	on a.appointment_id = t.appointment_id
WHERE
    a.status = 'completed'
        AND appointment_date >= CURDATE() - INTERVAL 12 MONTH
        and t.treatment_date >= a.appointment_date
GROUP BY d.doctor_name
ORDER BY no_of_appointments DESC
LIMIT 5;

delete from appointments where appointment_date is null;

#7what is the avg treatment cost handles by each doctor speciaization?
SELECT 
    d.specialization,
    ROUND(AVG(t.cost), 2) AS avg_treatment_cost
FROM
    treatment_valid_view t
        JOIN
    appointments a ON a.appointment_id = t.appointment_id
        JOIN
    doctors d ON a.doctor_id = d.doctor_id
GROUP BY d.specialization
ORDER BY avg_treatment_cost DESC;

#8which active doctors(based on active status) have not treated any patients in the last 6 months?
SELECT 
    d.doctor_name, d.active_status
FROM
    doctors d
WHERE
    d.active_status = 'active'
        AND d.doctor_id NOT IN (SELECT DISTINCT
            a.doctor_id
        FROM
            treatment_valid_view t
                JOIN
            appointments a ON t.appointment_id = a.appointment_id
        WHERE
            t.treatment_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH));

#9which doctor_city pairs generate the highest treatment revenue?
SELECT 
    d.doctor_name, d.city, ROUND(SUM(valid_cost), 2) revenue
FROM
    doctors d
        JOIN
    appointments a ON d.doctor_id = a.doctor_id
        JOIN
    treatment_valid_view t ON a.appointment_id = t.appointment_id
    where a.status = 'Completed'
and t.treatment_date >= a.appointment_date
GROUP BY d.doctor_name , d.city
ORDER BY revenue DESC
LIMIT 1;


#10what is the average age of patients receving treatments in 2023grouped by gender?

select p.gender, round(avg(timestampdiff(year,  p.birth_date, t.treatment_date)), 1) as avg_age
from treatments t 
join appointments a 
on a.appointment_id = t.appointment_id
join patients p 
on p.patient_id = a.patient_id
where year(t.treatment_date) =2023
and a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by p.gender;

#11do patients with private insurance have a higher average treatment cost than those with public or no insurance
select p.insurance_type, round(avg(t.valid_cost),2) as avg_cost
from patients p 
join appointments a 
on a.patient_id = p.patient_id
join treatment_valid_view t 
on a.appointment_id = t.appointment_id
where a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by p.insurance_type;

#12which city has the highest number of appointments per capita
SELECT 
    p.city,
    ROUND(COUNT(a.appointment_id) / COUNT(DISTINCT p.patient_id),
            0) AS appointments_per_capita
FROM
    appointments a
        JOIN
    patients p ON a.patient_id = p.patient_id
GROUP BY p.city
ORDER BY appointments_per_capita DESC
LIMIT 1;

#13what is the avg treatment cost for patients aged over 60 vs those under 30?
SELECT 
    CASE
        WHEN
            TIMESTAMPDIFF(YEAR,
                p.birth_date,
                t.treatment_date) > 60
        THEN
            'over 60'
        WHEN
            TIMESTAMPDIFF(YEAR,
                p.birth_date,
                t.treatment_date) < 30
        THEN
            'under 30'
    END AS age_group,
    ROUND(AVG(t.valid_cost), 0) AS avg_cost
FROM
    treatment_valid_view t
        JOIN
    appointments a ON t.appointment_id = a.appointment_id
        JOIN
    patients p ON a.patient_id = p.patient_id
WHERE
    TIMESTAMPDIFF(YEAR,
        p.birth_date,
        t.treatment_date) > 60
        OR TIMESTAMPDIFF(YEAR,
        p.birth_date,
        t.treatment_date) < 30
        and a.status = 'Completed'
and t.treatment_date >= a.appointment_date
GROUP BY age_group;

#14are male or female patients more likel to cancel appointments?

SELECT 
    p.gender, round(avg(a.status = 'Cancelled')*100,2) AS cancellation_rate
FROM
    appointments a
        JOIN
    patients p ON a.patient_id = p.patient_id
GROUP BY p.gender;

#15what is the total treatment cost per department per month in 2024
select a.department,MONTH(t.treatment_date) as month,
 round(sum(t.valid_cost),0) as total_cost
from appointments a 
join treatment_valid_view t 
on a.appointment_id=t.appointment_id
where year(t.treatment_date) = 2024
and a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by a.department, MONTH(t.treatment_date)
order by A.DEPARTMENT, month;

#16which five symptoms are associated with the highest average treatment cost?

select a.symptoms, round(avg(t.valid_cost),0) as avg_treatment_cost
from treatment_valid_view t
join appointments a 
on t.appointment_id=a.appointment_id
and a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by a.symptoms
order by avg_treatment_cost desc
limit 5;

#NOTE: a SQL view is created on treatments table to correct inflated costs.
#in this view, treatment costs for Cancelled and No Show appointments were set to zero
#to ensure accurate analysis
#view
create or replace view treatment_valid_view as 
select 
t.*,
a.status,
case
when a.status = 'completed' then t.cost 
else 0
end as valid_cost
from treatments t
join appointments a 
on t.appointment_id=a.appointment_id;

#17which appointment statuses result in zero revenue(treatment not provided)?

select status
from treatment_valid_view
group by status
having sum(valid_cost) = 0;

#18what is the monthly trend in total treatment revenue from january to december 2024?
select monthname(treatment_date) as treatment_month,
round(sum(valid_cost),0) as total_revenue
from treatment_valid_view t
join appointments a
on a.appointment_id = t.appointment_id
where year(treatment_date) = 2024
and a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by treatment_month
order by treatment_month desc;

#19which department has the highest average cost per completed appointments
select a.department, round(avg(t.valid_cost),0) as avg_cost
from treatment_valid_view t
join appointments a 
on a.appointment_id = t.appointment_id 
where a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by a.department
order by avg_cost desc
limit 1;



#20 do patients from urban cities have shorter appointment to treatment gaps compared to rural cities
select city, count(*) as patient_count
from patients 
group by city 
order by patient_count desc
limit 30;

create table temp_urban_city(city varchar(20));
insert into temp_urban_city(city)
values ('Davidside'),('New Jennifer'),('Smithfurt'),
('Port Amanda'),('Williamsmouth'),('South David'),('New Elizabeth'),
('West Thomas'),('Lake Elizabeth'),('Travischester'),('Paultown'),('Davischester'),
('Thomasville'),('East Tina'),('Port Julie'),('East Jamesmouth'),('Jamesfurt'),
('West James'),('Kevinfort'),('Lake Jonathan'),('Davidville'),('Stevenside'),('South Dustintown'),
('Hernandezmouth'),('Danielburgh'),('Valdezfort');
select * from temp_urban_city;

select case when p.city in (select city from temp_urban_city) then 'urban'
else 'rural' end as area_type,
round(avg(datediff(t.treatment_date, a.appointment_date)),1) as avg_gap_days
from appointments a 
join  treatments t 
on a.appointment_id = t.appointment_id
join patients p 
on a.patient_id = p.patient_id
where a.status = 'Completed'
and t.treatment_date >= a.appointment_date
group by area_type;

#21which doctor handles the most high cost treatments?
select d.doctor_name , round(sum(v.valid_cost),0) high_cost
from doctors d 
join appointments a 
on d.doctor_id = a.doctor_id
join treatment_valid_view v 
on a.appointment_id = v.appointment_id
where a.status = 'Completed'
and v.treatment_date >= a.appointment_date
group by d.doctor_name
order by high_cost desc
limit 5;

#22count of the most high cost treatments(>4k)?
select d.doctor_name , count(*) as high_cost_treatment
from doctors d 
join appointments a 
on d.doctor_id = a.doctor_id
join treatment_valid_view v 
on a.appointment_id = v.appointment_id
where a.status = 'Completed'
and v.valid_cost > 4000
and v.treatment_date >= a.appointment_date
group by d.doctor_name
order by high_cost_treatment desc
limit 5;

#23 which insurance type is associated with the longest delay between appointment and treatment?
select p.insurance_type, round(avg(datediff(v.treatment_date, a.appointment_date)),0) as avg_delay_days
from treatment_valid_view v
join appointments a
on a.appointment_id = v.appointment_id
join patients p 
on  p.patient_id = a.patient_id
where a.status = 'completed'
and v.treatment_date >= a.appointment_date
group by p.insurance_type
order by avg_delay_days desc;

#count of patients per insurance type
select insurance_type, count(*) as count_of_patients_per_insurance_type
from patients
group by insurance_type
order by count_of_patients_per_insurance_type desc;

#count of patients per insurance type by department
select a.department, p.insurance_type, count(distinct p.patient_id) as patient_count
from treatment_valid_view v
join appointments a
on a.appointment_id = v.appointment_id
join patients p 
on  p.patient_id = a.patient_id
where a.status = 'completed'
and v.treatment_date >= a.appointment_date
group by p.insurance_type, a.department
order by p.insurance_type, a.department;

#patients count per insurance type month(of treatment)
select p.insurance_type, monthname(v.treatment_date) as treatment_month ,
count(distinct p.patient_id) as patient_count
from treatment_valid_view v
join appointments a
on a.appointment_id = v.appointment_id
join patients p 
on  p.patient_id = a.patient_id
where a.status = 'completed'
and year(v.treatment_date) = 2024
and v.treatment_date >= a.appointment_date
group by p.insurance_type, treatment_month
order by p.insurance_type, treatment_month;


#24what is the avgerage cost per treatment by gender and department?
select a.department, p.gender, round(avg(v.valid_cost),0) as avg_cost_per_treatment
from appointments a 
join patients p 
on a.patient_id = p.patient_id
join treatment_valid_view v 
on a.appointment_id = v.appointment_id
where a.status = 'completed'
and v.treatment_date >= a.appointment_date
group by a.department, p.gender
order by avg_cost_per_treatment desc;






