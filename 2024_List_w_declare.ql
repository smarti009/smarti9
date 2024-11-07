---- ELECTION DAY Polling Location Info Template --------------------------------------------
---- Includes additional polling location information--------------------------------- 
---- 1. edit all variables below (lines 4,5)
declare county string default 'Cobb'; -- which county you want to pull
declare precinct_name string default 'Ac1a';  -- which precinct you want to pull

-------- 2. change name of table ---------
create or replace table demscoord24.ga.template_[countyname]_[precinct_name]_text as

with voted_list as (
    select
        person_id
        , early_voted
    from `demscoord24.avev_ga.national_reporting_snapshot`
    where
        early_voted = 1
)

,universe_list as (
    select
        p.person_id
        ,uni.vanid
        ,p.household_id
    from `demscoord24.ga.ff__08_texting` as uni
    left join `demscoord24.analytics_ga.person` as p using(person_id)
    left join voted_list using(person_id)
    left join `avev_ga.national_reporting_snapshot` nrs on nrs.myv_van_id=uni.vanid
    where target_type='1. GOTV'
    and voted_list.person_id is null
)

, opt_out as (
    select 
        left(cell,10) as cell
    from `demscoord24.scale_to_win_sms_raw_ga.scale_to_win_sms_raw__opt_outs`
)


,rep_ids_myv as (
    select
        cp.phone_number
        ,csr.myv_van_id
    from `demscoord24.vansync_ga.contacts_survey_responses_myv` as csr
    left join `demscoord24.vansync_ga.contacts_phones_myv` as cp
        on csr.myv_van_id = cp.myv_van_id
    where csr.survey_response_id in ("2574329", "2574330", "2574331", "2574751", "2495597", "2495598", "2495601", "2495605", "2493346", "2493347", "2493348", "2493349")
)

   select distinct
        p.myv_van_id as vanid
        ,coalesce(initcap(first_name),"friend") as first_name
        ,initcap(p.last_name) as last_name
        ,bp.best_cell as cell
        ,geo.county_name
        ,pl.polling_location
        ,pl.polling_address
    from universe_list as a
    left join `demscoord24.analytics_ga.person` as p using(person_id)
    left join `demscoord24.analytics_ga.all_scores` as s using(person_id)
    left join `demscoord24.states_ga.states_best_phones` as bp using(person_id)
    left join demscoord24.states_ga.states_geographies as geo on p.van_precinct_id=geo.van_precinct_id
    left join `demscoord24.vansync_ga.polling_locations` as pl on pl.van_precinct_id=p.van_precinct_id
    left join rep_ids_myv on p.myv_van_id = rep_ids_myv.myv_van_id
    left join opt_out on opt_out.cell=bp.best_cell
    where
        rep_ids_myv.myv_van_id is null
        and opt_out.cell is null
        and s.harris_support_score_targeting>.6
        and bp.best_cell is not null
        and geo.county_name= county
        and p.van_precinct_name= precinct_name
