SELECT
c.state_code,
assignment_id,
CONCAT(u.first_name, " ", u.last_name) AS observer_name,
vl.name AS location_name,
vl.city,
vl.county_id,
MAX(DATETIME(c.last_modified, 'America/New_York')) AS last_checkin,
case when wait_time = 'no_line' then 'No Line' when wait_time = 'thirty_min' then '30 min' when wait_time = 'one_hour' then '1 hr' when wait_time = 'two_hours' then "2 hrs" when wait_time = 'three_hours' then '3 hrs' when wait_time = 'eight_plus_hours' then '8+ hours' when wait_time =
'four_hours' then '4 hrs' when wait_time = 'seven_hours' then '7 hrs' when wait_time = 'five_hours' then '5 hours' when wait_time = 'six_hours' then '6 hrs' when wait_time = 'eight_hours' then '8 hrs' else wait_time end as wait_time
FROM
`democrats.lbj_audit_ga.assignment_checkin` c
LEFT JOIN
`democrats.lbj_audit_ga.assignment_assignment` a
ON CAST(c.assignment_id AS INT) = a.id
LEFT JOIN
`democrats.lbj_audit_ga.assignment_votinglocation` vl
ON CAST(a.location_id AS INT) = vl.id
LEFT JOIN
`democrats.lbj_audit_ga.lbj_user_lbjuser` u
ON CAST(c.user_id AS INT) = u.id
WHERE
DATE(DATETIME(c.time, 'America/New_York')) = CURRENT_DATE('America/New_York')
AND assignment_id IS NOT NULL and wait_time in ('one_hour', 'two_hours', 'three_hours', 'eight_plus_hours', 'four_hours', 'eight_hours', 'seven_hours', 'five_hours', 'six_hours') AND a.state_code ='GA'
GROUP BY
c.state_code,
assignment_id,
observer_name,
location_name,
vl.city,
vl.county_id,
wait_time
ORDER BY
last_checkin DESC;
