create or replace table demscoord24.ga.1101_monday_confirms as
with opt_out as (
    select 
        cell
    from `demscoord24.scale_to_win_sms_raw_ga.scale_to_win_sms_raw__opt_outs`
)

, rep_ids_myc as (
    select
        myc_van_id
    from `demscoord24.vansync_ga.contacts_survey_responses_myc` as id
    where id.survey_response_id in ("2574331","2574329","2574330","2574328") 
)

, ImportListHere as (
  select VANID from demscoord24.ga.1101_eventconfirms
)

, get_phones_boi as(

select a.VANID, b.phone_number as best_cell, "1" as priority FROM ImportListHere a
inner join `demscoord24.vansync_ga.contacts_phones_myc` b on cast(a.VANID as string) = b.myc_van_id
where is_preferred_phone is true

union distinct

select a.VANID, b.phone_number as best_cell, "2" as priority FROM ImportListHere a
inner join `demscoord24.vansync_ga.contacts_phones_myc` b on cast(a.VANID as string) = b.myc_van_id
where suppressed_by_user_id is null

union distinct

SELECT a.VANID, e.best_cell, "3" as priority FROM ImportListHere a
inner join `demscoord24.vansync_ga.person_records_myc` c on cast(a.VANID as string) = c.myc_van_id
inner join `demscoord24.analytics_ga.person` d using(myv_van_id)
inner join `demscoord24.states_ga.states_best_phones` e using(person_id)

union distinct

SELECT a.VANID, e.best_cell, "4" as priority FROM ImportListHere a
inner join `demscoord24.vansync_ga.person_records_myc` c on cast(a.VANID as string) = c.myc_van_id
inner join `demscoord24.vansync_ga.contacts_addresses_myc` d using(myc_van_id)
inner join `demscoord24.analytics_ga.person` b
on upper(d.county_name) = upper(b.county_name)
and upper(c.first_name) = upper(b.first_name)
and upper(c.last_name) = upper(b.last_name)
inner join `demscoord24.states_ga.states_best_phones` e using(person_id)

order by priority asc
)

select distinct
p.VANID as vanid
,coalesce(p.FirstName,'friend') as first_name
,p.LastName as last_name
,bp.best_cell as cell
,p.EventName
,p.LocationName
,p.LocationID
,p.StartDate as event_date
,p.ShiftStartTime as monday_shift_time
,p.Shift as shift_name
,p.Role
from `demscoord24.ga.1101_eventconfirms` as p
left join `vansync_ga.person_records_myc` pr on cast(p.VANID as string)=pr.myc_van_id
left join get_phones_boi bp on p.VANID = bp.VANID
left join rep_ids_myc using(myc_van_id)
left join opt_out on opt_out.cell=bp.best_cell
where p.StartDate = '2024-11-04'
qualify row_number() over(partition by vanid order by ShiftStartTime) = 1
