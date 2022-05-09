DECLARE adsets_arr array<string>;
DECLARE ads_arr array<string>;
DECLARE adset_len int64;
DECLARE current_key int64 default 0;
DECLARE current_adset string;
DECLARE script_query string;
-- 

-- SELECT * from unnest(ads_arr);


-- create or replace table <dataset>.adsets as
-- SELECT adset_name, row_number() over() as key_ FROM `<project_id>.<dataset>.adsets_` order by key_ asc limit 15;


--A TABLE WITH ADSETS, ADS, SPEND > 0
create or replace table <dataset>.as_a_s
as SELECT adset_name, ad_name,spend from `<project_id>.<facebook-dataset>.<table>` where spend > 0;

create or replace table <dataset>.adset_spend
as SELECT adset_name, sum(spend) as adset_spend from `<project_id>.<dataset>.as_a_s` group by (adset_name);


--CREATE AN ARRAY FROM DISTINCT ADSETS, ADS THAT HAVE SOME SPEND
SET adsets_arr = (select ARRAY_AGG(distinct adset_name) from `<project_id>.<dataset>.as_a_s`);
SET ads_arr = (select ARRAY_AGG(distinct ad_name) from `<project_id>.<dataset>.as_a_s`);

-- create or replace table <dataset>.adsets_num 
-- as select *, row_number()over() as key_  from unnest(adsets_arr) as ad_sets order by key_ asc;

-- create or replace table <dataset>.ad_num 
-- as select *, row_number()over() as key_  from unnest(ads_arr) as ads order by key_ asc;

create or replace table <dataset>.facebook_indexed as 
SELECT
`<project_id>.<facebook-dataset>.<table>`.adset_name,
`<project_id>.<facebook-dataset>.<table>`.ad_name,
`<project_id>.<facebook-dataset>.<table>`.spend,
`<project_id>.<facebook-dataset>.<table>`.action,
`<project_id>.<facebook-dataset>.<table>`.cost_per_action,
`<project_id>.<dataset>.adsets_num`.key_,
`<project_id>.<dataset>.adset_spend`.adset_spend
FROM `<project_id>.<facebook-dataset>.<table>`
LEFT JOIN  `<project_id>.<dataset>.adsets_num` on `<project_id>.<facebook-dataset>.<table>`.adset_name = `<project_id>.<dataset>.adsets_num`.ad_sets
LEFT JOIN `<project_id>.<dataset>.adset_spend` on `<project_id>.<facebook-dataset>.<table>`.adset_name = `<project_id>.<dataset>.adset_spend`.adset_name;

SET adset_len = (SELECT count(distinct key_) FROM `<project_id>.<dataset>.facebook_indexed`);
SET current_adset = "(select ad_sets from `<project_id>.<dataset>.adsets_num` where key_ = @ck)";

WHILE current_key < adset_len
DO 
SET current_key = current_key + 1;
EXECUTE IMMEDIATE
"CREATE OR REPLACE TABLE `<project_id>.<dataset>.adset_"||current_key||"` as SELECT * FROM `<project_id>.<dataset>.facebook_indexed` where key_ = @key"
USING current_key as key;
END WHILE;

SET current_key = 0;

WHILE current_key < adset_len
DO 
SET current_key = current_key + 1;
EXECUTE IMMEDIATE
"CREATE OR REPLACE TABLE `<project_id>.<dataset>.adset_"||current_key||"_report`(Adset string, Adname string, Spend string, Results string, Cost_per_Result string, Acquisition string, CostPerAcq string)";
END WHILE
