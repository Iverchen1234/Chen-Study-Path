#part2
USE pharmacy_claims;
#set primary key for all the tables in database pharmacy_claims.
alter table dim_drug_brand
add primary key (drug_brand_generic_code);
alter table dim_drug_form
add primary key (drug_form_code);
alter table dim_patient_information
add primary key (member_id);
alter table dim_drug_name
add primary key (drug_ndc);
alter table fact_case_patient_drug
add column case_id int auto_increment primary key;

#set foreign key for fact table.
#dim_drug_brand 
alter table fact_case_patient_drug
add foreign key fact_case_patient_drug_brand_fk (drug_brand_generic_code)
references dim_drug_brand (drug_brand_generic_code)
on update cascade
on delete cascade;
#dim_drug_form
alter table fact_case_patient_drug
add foreign key fact_case_patient_drug_form_fk (drug_form_code)
references dim_drug_form (drug_form_code)
on update cascade
on delete cascade;
#dim_drug_name
alter table fact_case_patient_drug
add foreign key fact_case_patient_drug_name_fk (drug_ndc)
references dim_drug_name (drug_ndc)
on update cascade
on delete cascade;
#dim_patient_information
alter table fact_case_patient_drug
add foreign key fact_case_patient_information_fk (member_id)
references dim_patient_information (member_id)
on update cascade
on delete cascade;

#part 4
#1 identify the number of prescriptions grouped by drug name
select dim_drug_name.drug_name,count('drug_name') as count 
from fact_case_patient_drug
inner join dim_drug_name on dim_drug_name.drug_ndc = fact_case_patient_drug.drug_ndc
group by dim_drug_name.drug_name;


#2 calculate the members are over 50 years age, the number of prescriptions they fill and the total cost they paid and insurance paid 
SELECT count(fact_case_patient_drug.drug_ndc) as total_prescriptions, 
count(DISTINCT fact_case_patient_drug.member_id) as unique_members, 
sum(fact_case_patient_drug.copay) as sum_copay, 
sum(fact_case_patient_drug.insurancepaid) as sum_insurancepaid, 
CASE 
	WHEN dim_patient_information.member_age > 50 THEN 'age 50+'
	WHEN dim_patient_information.member_age < 50 THEN '<50'
END age
FROM dim_patient_information JOIN fact_case_patient_drug ON dim_patient_information.member_id = fact_case_patient_drug.member_id
GROUP BY age;


#3 identify the amount paid by the insurance for the most recent prescription fill date (member_id=10004).   
SELECT member_id,member_first_name, member_last_name, dim_drug_name.drug_name, a.MR_DATE,a.MR_PAID
from (select member_id, drug_ndc,
LEAD(fill_date,1,null) OVER(partition by member_id ORDER BY fill_date ASC) AS MR_DATE,
LEAD(insurancepaid,1,0) OVER(partition by member_id ORDER BY fill_date ASC) AS MR_PAID 
from fact_case_patient_drug) as a
inner join dim_drug_name USING (drug_ndc)
inner join dim_patient_information USING (member_id)
where member_id = 10004 and a.MR_DATE is not null;


    